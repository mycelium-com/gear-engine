class OrderStatusCheckJob < ApplicationJob
  queue_as :default
  discard_on Exception

  def perform(order:, final: false)
    # if order.time_left_before_expiration <= 0
    if OrderStatus.immutable?(order.status)
      Rails.logger.debug "Ignoring #{order} with status '#{OrderStatus.key_for(order.status)}'"
      return
    end

    result      = OrderStatusCheck.call(order: order)
    do_callback = result.order_changed
    if final || result.final
      result      = OrderStatusFinalize.call(order: order)
      do_callback ||= result.order_changed
    end
    OrderCallbackJob.broadcast_later(order: order) if do_callback
  end
end
