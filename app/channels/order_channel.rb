class OrderChannel < ApplicationCable::Channel

  def self.order_stream(order)
    "order_#{order.payment_id}"
  end

  def subscribed
    stream_from self.class.order_stream(order)
    OrderCallbackWebsocket.call(order: order)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def ensure_confirmation_sent
    # suppress message
  end

  # overrides default protocol for backward compatibility
  def transmit(data, via: nil)
    logger.debug "#{self.class.name} #{via}\n#{data}"
    payload = { channel_class: self.class.name, data: data, via: via }
    ActiveSupport::Notifications.instrument("transmit.action_cable", payload) do
      connection.transmit data
    end
  end
end

# TODO: when/if this system gets overloaded, upgrade to something like https://evilmartians.com/chronicles/anycable-actioncable-on-steroids