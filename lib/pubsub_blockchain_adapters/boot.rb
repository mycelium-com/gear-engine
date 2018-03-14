require 'celluloid/current'
require 'celluloid/io'

module PubSubBlockchainAdapters

  class OrderActor
    include Celluloid

    def status_check_stimulus(address:, currency:)
      OrderStimulateStatusCheck.call!(address: address, currency: currency)
    end

    def self.id
      :OrderActor
    end
  end


  class ElectrumRootActor
    include Celluloid
    include Celluloid::Notifications

    attr_accessor :currency, :address_status_changed_at
    DEBOUNCE_ADDRESS_STATUS_CHANGE = 42.seconds

    def initialize(currency:)
      self.currency                  = currency
      self.address_status_changed_at = {}
      subscribe ElectrumActor.address_status_changed_topic(currency: currency), :address_status_changed
    end

    def address_subscribe(address:)
      publish ElectrumActor.address_subscribe_topic(currency: currency), address: address
    end

    # different servers seems to return different status strings nearly at the same time,
    # so the evidence of change is message itself, not its content
    def address_status_changed(_, address:, **)
      changed = !address_status_changed_at.has_key?(address) || (Time.now - address_status_changed_at[address]) > DEBOUNCE_ADDRESS_STATUS_CHANGE
      if changed
        address_status_changed_at[address] = Time.now
        Actor[OrderActor.id].async.status_check_stimulus address: address, currency: currency
        Celluloid.logger.info { "[Electrum#{currency}] #{address} signal accepted at #{address_status_changed_at[address]}" }
      else
        Celluloid.logger.debug { "[Electrum#{currency}] #{address} signal ignored" }
      end
    end

    # https://electrumx.readthedocs.io/en/latest/protocol-basics.html#script-hashes
    def self.address_to_scripthash(address)
      script = BTC::Address.parse(address).script.to_hex
      binary = [script].pack('H*')
      hash   = Digest::SHA256.hexdigest(binary)
      hash.each_char.each_slice(2).reverse_each.to_a.join
    end
  end


  class ElectrumActor
    include Celluloid::IO
    include Celluloid::Notifications

    CommunicationError = Class.new(RuntimeError)

    attr_accessor :server, :currency

    finalizer :shutdown

    def initialize(server:, currency:)
      self.currency = currency
      self.server   = URI(server)
      subscribe ElectrumActor.address_subscribe_topic(currency: currency), :address_subscribe
      async.event_loop
      async.resume_monitoring
    end

    def address_subscribe(_, address:)
      connection.write JSON(id: Time.now.to_i, method: 'blockchain.address.subscribe', params: Array.wrap(address)).concat("\n")
      Celluloid.logger.info { "[Electrum#{currency}] blockchain.address.subscribe(#{address}) via #{server}" }
    end

    def event_loop
      loop do
        result = connection.gets
        Rails.logger.debug { "[Electrum#{currency}] message from #{server}\n#{result.inspect}" }
        raise CommunicationError if result.nil?
        parsed = JSON(result)
        if 'blockchain.address.subscribe' == parsed['method']
          data = {
              address: parsed['params'][0],
              status:  parsed['params'][1]
          }
          publish ElectrumActor.address_status_changed_topic(currency: currency), data
        end
      end
    end

    def connection
      @connection ||= begin
        tcp_socket = TCPSocket.open server.host, server.port
        if 'tcp-tls' == server.scheme
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.set_params verify_mode: OpenSSL::SSL::VERIFY_NONE
          socket = SSLSocket.new(tcp_socket, ssl_context)
          socket.connect
          socket.sync_close = true
          socket
        else
          tcp_socket
        end
      end
    end

    def shutdown
      @connection&.close
    end

    # TODO: when/if single process would be unable to handle all orders consider sharding strategy
    def resume_monitoring
      # TODO: limit scope by currency
      StraightServer::Order.where('status < 2').select(:address).paged_each do |order|
        async.address_subscribe address: order.address
      end
    end

    def self.address_subscribe_topic(currency:)
      "ElectrumActor_address_subscribe_#{currency}"
    end

    def self.address_status_changed_topic(currency:)
      "ElectrumActor_address_status_changed_#{currency}"
    end

  end


  class Supervisor < Celluloid::Supervision::Container

    def self.servers
      Rails.application.config.pubsub_blockchain_adapters[:electrum]
    end

    def self.currencies
      servers.map { |item| item[:currency] }.uniq
    end

    supervise type: OrderActor, as: OrderActor.id
    currencies.each do |currency|
      supervise type: ElectrumRootActor, as: :"Electrum#{currency}", args: [currency: currency]
    end
    servers.each_with_index do |server, i|
      supervise type: ElectrumActor, as: :"ElectrumActor#{i}", args: [server]
    end
  end
end

Celluloid.logger = Rails.logger
Celluloid.boot
PubSubBlockchainAdapters::Supervisor.run!