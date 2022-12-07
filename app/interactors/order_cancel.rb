class OrderCancel
  include Interactor
  include InteractorLogs

  delegate :order, to: :context

  def call
    if order.status == OrderStatus::NEW
      order.status = OrderStatus::CANCELED
      order.save_changed
      OrderCallbackJob.broadcast_later(order: order)
    else
      context.fail!(response: {
        status: :unprocessable_entity,
        json:   { error: "Order is not cancelable" }
      })
    end
  end
end
