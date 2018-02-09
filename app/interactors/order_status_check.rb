class OrderStatusCheck
  include Interactor

  def call
    order = context.order
    Rails.logger.info "OrderStatusCheck #{order.inspect}"
    order.on_accepted_transactions_updated = lambda do
      order.gateway.order_accepted_transactions_updated order
    end
    order.status(reload: true)
    order.save
  end
end
