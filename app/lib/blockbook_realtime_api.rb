# frozen_string_literal: true

class BlockbookRealtimeAPI

  private_class_method :new

  class << self
    def instance(network:, url:)
      raise ArgumentError if url.blank?
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
    Rails.logger.debug logger_tagged('connect', url)
    Iodine.connect(url: url, handler: self, ping: 3)
    nil
  end

  # Iodine hooks

  def on_open(iodine_conn)
    Rails.logger.debug logger_tagged('on_open', inspect_iodine_conn(iodine_conn))
    @connection = iodine_conn
    make_queued_requests
  end

  def on_message(iodine_conn, message)
    Rails.logger.debug logger_tagged('on_message', "#{message}(from #{inspect_iodine_conn(iodine_conn)})")
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
      Rails.logger.debug logger_tagged('on_close_before_on_open', inspect_iodine_conn(iodine_conn))
    else
      Rails.logger.debug logger_tagged('on_close_reconnection', inspect_iodine_conn(iodine_conn))
      connection.close # just in case
      delay_reconnection
      connect
      resubscribe
    end
  end

  # Blockbook Websocket API
  # @see https://github.com/trezor/blockbook/blob/master/docs/api.md#websocket-api

  def subscribe(address, &callback)
    Rails.logger.debug logger_tagged('subscribe', address.inspect)
    raise ArgumentError if address.blank?
    subscribed[address] = AddressSubscription.new([], callback)
    resubscribe
  end

  def unsubscribe(*addresses)
    return if addresses.blank?
    Rails.logger.debug logger_tagged('unsubscribe', addresses.inspect)
    addresses.each do |address|
      subscribed&.delete(address)
    end
    resubscribe
  end

  def resubscribe
    Rails.logger.debug logger_tagged('resubscribe', subscribed.keys.inspect)
    make_or_queue_request(
      id:     '',
      method: 'subscribeAddresses',
      params: {
        addresses: subscribed.keys
      }
    )
  end

  def each_subscribed_address(&block)
    subscribed.each_key(&block)
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
      Rails.logger.debug logger_tagged('subscription_callback', subscription.inspect)
      begin
        result = subscription.callback.call(subscription.transactions.dup)
        if result == :unsubscribe
          unsubscribe(address)
        end
      rescue RuntimeError => ex
        Sentry.capture_exception ex
        Rails.logger.error logger_tagged('subscription_callback_failed', ex.inspect)
      end
    end
  end

  def make_or_queue_request(id:, method:, params:)
    request = "#{JSON.dump(id: id, method: method, params: params)}\n".freeze
    if connection&.open?
      connection.write request
      true
    else
      requests_queue << request
      false
    end
  end

  def make_queued_requests
    return if requests_queue.empty?
    Rails.logger.debug logger_tagged('make_queued_requests', requests_queue.join)
    until requests_queue.empty? do
      request = requests_queue.shift
      connection.write request
    end
    Rails.logger.debug logger_tagged('made_queued_requests')
  end

  def logger_tagged(event, data = nil)
    thread = "Thread#{Thread.current.object_id}"
    conn   = "IodineConn#{connection&.object_id}"
    "[BlockbookRealtimeAPI] [#{thread}] [#{conn}] [#{timestamp}] [#{event}] [BB_#{network}] [#{url}]#{data.nil? ? nil : "\n"}#{data}"
  end

  def inspect_iodine_conn(iodine_conn)
    "[IodineConn#{iodine_conn&.object_id}] #{iodine_conn.inspect}"
  end

  def timestamp
    Process.clock_gettime(Process::CLOCK_MONOTONIC).round(5)
  end

  def delay_reconnection
    sleep 0.25
  end

  AddressSubscription = Struct.new(:transactions, :callback)
end