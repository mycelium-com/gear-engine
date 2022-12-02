class BlockbookRealtimeAPI

  private_class_method :new

  class << self
    def instance(network:, url:)
      URI(url)
      network = BlockchainNetwork[network]

      registry[[network, url]] ||= new(network: network, url: url)
    end

    def each_instance(network: nil, &block)
      per_thread_initializer
      if network.nil?
        registry.each_value(&block)
      else
        network = BlockchainNetwork[network]
        registry.select { |k, _v| k.first == network }.each_value(&block)
      end
    end

    private

    def registry
      Thread.current[:BlockbookRealtimeAPI] ||= {}
    end

    def per_thread_initializer
      BlockchainNetwork.keys.each do |network|
        urls = ENV["BLOCKBOOK_#{network}_WS"].to_s.split(',')
        urls.each do |url|
          BlockbookRealtimeAPI.instance(url: url, network: network)
        end
      end
    end
  end

  attr_reader :url, :network, :connection, :subscribed, :requests_queue

  def initialize(url:, network:)
    @url            = url
    @network        = network
    @subscribed     = {}
    @requests_queue = []
    connect
  end

  def connect
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} connect] #{url}"
    Iodine.connect(url: url, handler: self, ping: 3)
    nil
  end

  # Iodine hooks

  def on_open(iodine_conn)
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} on_open] #{iodine_conn.inspect}"
    @connection = iodine_conn
    make_queued_requests
  end

  def on_message(iodine_conn, message)
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} on_message] #{iodine_conn.inspect}\n#{message}"
    parsed = JSON(message).fetch('data') rescue {}

    address = parsed.fetch('address', nil)
    tx      = parsed.fetch('tx', nil)
    if address.present? && tx.present? && subscribed.has_key?(address)
      on_subscribed_address_tx(address: address, tx: tx)
    end
  end

  def on_close(iodine_conn)
    if connection.nil?
      # why?
      Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} on_close_before_on_open] #{iodine_conn.inspect}"
    else
      Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} on_close_reconnection] #{connection.inspect} == #{iodine_conn.inspect}"
      connection.close # just in case
      delay_reconnection
      connect
      resubscribe
    end
  end

  # Blockbook Websocket API
  # @see https://github.com/trezor/blockbook/blob/master/docs/api.md#websocket-api

  def subscribe(address, &callback)
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} subscribe] #{connection.inspect} #{address.inspect}"
    raise if address.blank?
    subscribed[address] = AddressSubscription.new([], callback)
    resubscribe
  end

  def unsubscribe(address)
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} unsubscribe] #{connection.inspect} #{address.inspect}"
    subscribed&.delete(address)
    resubscribe
  end

  def resubscribe
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} resubscribe] #{connection.inspect}\n#{subscribed.keys.inspect}"
    make_or_queue_request(
      id:     '',
      method: 'subscribeAddresses',
      params: {
        addresses: subscribed.keys
      }
    )
  end

  private

  def on_subscribed_address_tx(address:, tx:)
    transaction               = Straight::Transaction.new
    transaction.tid           = tx.fetch('txid')
    transaction.block_height  = tx.fetch('blockHeight')
    transaction.confirmations = tx.fetch('confirmations')
    transaction.amount        = tx.fetch('vout').map { |out|
      if out.fetch('isAddress') && out.fetch('addresses') == [address]
        out.fetch('value').to_i
      else
        0
      end
    }.reduce(:+)

    subscription = subscribed.fetch(address)
    subscription.transactions << transaction.freeze
    if subscription.callback.respond_to?(:call)
      Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} subscription_callback] #{connection} #{subscription.inspect}"
      begin
        result = subscription.callback.call(subscription.transactions.dup)
        if result == :unsubscribe
          unsubscribe(address)
        end
      rescue RuntimeError => ex
        Rails.logger.error "[BlockbookRealtimeAPI] [#{timestamp} subscription_callback_failed] #{connection}\n#{ex.inspect}"
      end
    end
  end

  def make_or_queue_request(id:, method:, params:)
    request = "#{JSON.dump(id: id, method: method, params: params)}\n"
    if connection&.open?
      connection.write request
    else
      requests_queue << request
    end
  end

  def make_queued_requests
    return if requests_queue.empty?
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} make_queued_requests] #{connection}\n#{requests_queue.join}"
    until requests_queue.empty? do
      request = requests_queue.shift
      connection.write request
    end
    Rails.logger.debug "[BlockbookRealtimeAPI] [#{timestamp} made_queued_requests] #{connection}"
  end

  def timestamp
    Process.clock_gettime(Process::CLOCK_MONOTONIC).round(5)
  end

  def delay_reconnection
    sleep 0.25
  end

  AddressSubscription = Struct.new(:transactions, :callback)
end