class OrderSubscribeToStatusChange
  include Interactor
  include InteractorLogs

  delegate :order, to: :context

  def call
    unless defined?(Celluloid) && Celluloid.running?
      Rails.logger.debug "Skipping: Celluloid not enabled"
      return
    end
    name    = :"Electrum#{order.gateway.blockchain_network}"
    actor   = Celluloid::Actor[name]
    if actor
      actor.address_subscribe address: order.address
    else
      Rails.logger.warn "Missing actor #{name}"
    end
  end
end
