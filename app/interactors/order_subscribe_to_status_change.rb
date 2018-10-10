class OrderSubscribeToStatusChange
  include Interactor
  include InteractorLogs

  delegate :order, to: :context

  def call
    name    = :"Electrum#{order.gateway.blockchain_network}"
    actor   = Celluloid::Actor[name]
    if actor
      actor.address_subscribe address: order.address
    else
      Rails.logger.warn { "[OrderSubscribeToStatusChange] Missing actor #{name}" }
    end
  end
end
