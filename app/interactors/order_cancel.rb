class OrderCancel
  include Interactor

  def call
    order = context.order
    if order.cancelable?
      order.cancel
      OrderCallbackJob.broadcast_later(order: order)
    else
      context.fail! error: "Order is not cancelable"
    end
  end
end
