class OrderStatusCheck
  include Interactor

  FINAL_STATUSES = %i[paid overpaid].map { |s| Straight::Order::STATUSES[s] }.to_set.freeze

  def call
    order = context.order
    Rails.logger.info { "#{order} [#{self.class.name}] #{order.inspect}" }
    order.on_accepted_transactions_updated = lambda do
      # order.gateway.order_accepted_transactions_updated order
      context.order_changed = true
    end
    order.status reload: true
    context.final = FINAL_STATUSES.include?(order.status)
  end
end
