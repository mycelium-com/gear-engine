class OrderStatusCheckJob < ApplicationJob
  queue_as :default

  def perform(order:, final: false)
    # if order.time_left_before_expiration <= 0
    # if StraightServer::Thread.interrupted?(thread: ::Thread.current)
    result = OrderStatusCheck.call(order: order)
    do_callback = result.order_changed
    if final || result.final
      result = OrderFinalize.call(order: order)
      do_callback ||= result.order_changed
    end
    if do_callback
      OrderCallbackJob.new(order: order, channel: OrderCallbackJob::WEBSOCKET).enqueue
      OrderCallbackJob.new(order: order, channel: OrderCallbackJob::HTTP).enqueue
    end
  end
end
