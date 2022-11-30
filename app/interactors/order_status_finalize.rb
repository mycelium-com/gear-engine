class OrderStatusFinalize
  include Interactor
  include InteractorLogs

  delegate :order, to: :context

  def call
    case order.status
    when OrderStatus::NEW
      order.status = OrderStatus::EXPIRED
      context.order_changed = true
    when OrderStatus::PARTIALLY_PAID
      order.status = OrderStatus::UNDERPAID
      context.order_changed = true
    when OrderStatus::UNCONFIRMED
      # let's keep it unconfirmed, marking as expired makes no sense
      # TODO: if it has at least 1 confirmation, monitor until it's fully confirmed
      # Hotfixed via crontask: 0 */2 * * * /usr/bin/docker exec gear-prd_engine_1 bin/rails runner 'Order.orm.where(status: 1).each{|o| OrderStatusCheckJob.new(order: Order.new(o), final: false).enqueue }' > /dev/null 2>&1
    end
    order.save_changed
  end
end
