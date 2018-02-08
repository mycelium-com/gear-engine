class OrderStatusCheckJob < ApplicationJob
  queue_as :default

  def perform(order)
    OrderStatusCheck.call(order: order)
  end
end
