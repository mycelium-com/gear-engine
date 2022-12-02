class OrderStatusCheckJob < ApplicationJob
  queue_as :default
  discard_on Exception

  def perform(order:, final: false)
    do_callback = false

    Order.db.transaction do
      order.lock!
      if OrderStatus.immutable?(order.status)
        Rails.logger.debug "Ignoring #{order} with status '#{OrderStatus.key_for(order.status)}'"
      else
        result      = OrderStatusCheck.call(order: order)
        do_callback = result.order_changed
        if final || result.final
          result      = OrderStatusFinalize.call(order: order)
          do_callback ||= result.order_changed
        end
      end
    end

    OrderCallbackJob.broadcast_later(order: order) if do_callback
  end
end
