class OrderCallbackJob < ApplicationJob
  queue_as :urgent

  HTTP      = 'Http'
  WEBSOCKET = 'Websocket'

  def perform(order:, channel:)
    "OrderCallback#{channel}".constantize.call!(order: order)
  end
end
