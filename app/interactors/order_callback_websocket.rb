class OrderCallbackWebsocket
  include Interactor

  def call
    order = context.order
    Rails.logger.info { "#{order} [#{self.class.name}] #{order.inspect}" }
    ActionCable.server.broadcast OrderChannel.order_stream(order), order.to_h
  end
end
