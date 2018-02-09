class OrderFinalize
  include Interactor

  def call
    order    = context.order
    statuses = order.class::STATUSES
    if order.status == statuses[:partially_paid]
      order.status = statuses[:underpaid]
    elsif self.status == statuses[:unconfirmed]
      # let's keep it unconfirmed, marking as expired makes no sense
      # TODO: if it has at least 1 confirmation, monitor until it's fully confirmed
    elsif order.status == statuses[:new]
      order.status = statuses[:expired]
    end
    order.save
    StraightServer.insight_client&.remove_address order.address
  end
end
