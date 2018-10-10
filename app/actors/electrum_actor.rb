class ElectrumActor
  include Celluloid::IO
  include Celluloid::Notifications
  include CelluloidLogs

  attr_accessor :url, :network

  finalizer :shutdown

  def initialize(url:, network:)
    self.network = network
    self.url      = URI(url)
    subscribe ElectrumActor.address_subscribe_topic(network: network), :address_subscribe_callback
    async.event_loop
    async.resume_monitoring
  end

  def address_subscribe(address:)
    connection.write JSON(id: Time.now.to_i, method: 'blockchain.address.subscribe', params: Array.wrap(address)).concat("\n")
    logger info: "blockchain.address.subscribe(#{address}) via #{url}"
  end

  def address_subscribe_callback(_, **args)
    address_subscribe(**args)
  end

  def event_loop
    loop do
      if connected?
        result = connection.gets
      else
        sleep 4
        next
      end
      if result.nil?
        logger warn: "[CommunicationError] empty message from #{url}"
        reconnect
        next
      else
        logger debug: "message from #{url}\n#{result.inspect}"
      end
      parsed = JSON(result)
      if 'blockchain.address.subscribe' == parsed['method']
        data = {
          address: parsed['params'][0],
          status:  parsed['params'][1]
        }
        publish ElectrumActor.address_status_changed_topic(network: network), data
      end
    end
  end

  def connection
    @connection ||= begin
      logger info: "[Connecting] #{url}"
      tcp_socket = TCPSocket.open url.host, url.port
      if 'tcp-tls' == url.scheme
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

  def connected?
    !@connection.nil?
  end

  def reconnect
    logger debug: "[Reconnecting] #{url}"
    shutdown
    resume_monitoring
  end

  def shutdown
    @connection&.close
    @connection = nil
  end

  # TODO: when/if single process would be unable to handle all orders consider sharding strategy
  def resume_monitoring
    resumed = []
    Order.each_pending(network) do |order|
      resumed << order.id
      async.address_subscribe address: order.address
    end
    logger debug: "[MonitoringResumed] #{resumed.size} orders: #{resumed.inspect}"
  end

  def logger_tags
    "Electrum#{network}"
  end

  def self.address_subscribe_topic(network:)
    "ElectrumActor_address_subscribe_#{network}"
  end

  def self.address_status_changed_topic(network:)
    "ElectrumActor_address_status_changed_#{network}"
  end
end