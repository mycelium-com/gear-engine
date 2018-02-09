class OrderStatusCheckJob < ApplicationJob
  queue_as :default

  def perform(order:, final: false)
    # if order.time_left_before_expiration <= 0
    # if StraightServer::Thread.interrupted?(thread: ::Thread.current)
    OrderStatusCheck.call(order: order)
    OrderFinalize.call(order: order) if final
  end
end
