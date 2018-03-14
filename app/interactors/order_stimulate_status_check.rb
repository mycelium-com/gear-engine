class OrderStimulateStatusCheck
  include Interactor

  def call
    context.order = order = StraightServer::Order[address: context.address] # TODO: scope by context.currency
    if order
      if order.finalized?
        Rails.logger.debug { "[OrderStimulateStatusCheck] Order is finalized, ignoring\n#{context.inspect}" }
      else
        OrderStatusCheckJob.new(order: context.order, final: false).enqueue
      end
    else
      Rails.logger.debug { "[OrderStimulateStatusCheck] Order not found\n#{context.inspect}" }
    end
  end
end
