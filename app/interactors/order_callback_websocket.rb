class OrderCallbackWebsocket
  include Interactor

  def call
    order = context.order
    Rails.logger.info { "#{order} [#{self.class.name}] #{order.inspect}" }
    ActionCable.server.broadcast "order_#{order.payment_id}", order.to_h
  end
end
