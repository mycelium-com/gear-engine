class OrderStimulateStatusCheck
  include Interactor
  include InteractorLogs

  delegate :address, :order, to: :context

  def call
    context.order = Order.find_by_address(address)
    if order
      if OrderStatus.immutable?(order.status)
        Rails.logger.debug "Ignoring #{order} with status '#{OrderStatus.key_for(order.status)}'"
      else
        OrderStatusCheckJob.new(order: order, final: false).enqueue
      end
    else
      Rails.logger.warn "Not found order with address #{address.inspect}"
    end
  end
end
