class OrderStatusFinalize
  include Interactor

  def call
    order    = context.order
    statuses = order.class::STATUSES
    case order.status
    when statuses.fetch(:new)
      order.status = statuses.fetch(:expired)
      context.order_changed = true
    when statuses.fetch(:partially_paid)
      order.status = statuses.fetch(:underpaid)
      context.order_changed = true
    when statuses.fetch(:unconfirmed)
      # let's keep it unconfirmed, marking as expired makes no sense
      # TODO: if it has at least 1 confirmation, monitor until it's fully confirmed
    end
    # StraightServer.insight_client&.remove_address order.address
  end
end
