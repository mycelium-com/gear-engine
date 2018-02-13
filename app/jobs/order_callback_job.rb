class OrderCallbackJob < ApplicationJob
  queue_as :urgent
  retry_on Exception, wait: :exponentially_longer, attempts: 21, queue: :default

  HTTP      = 'Http'
  WEBSOCKET = 'Websocket'

  def perform(order:, channel:)
    "OrderCallback#{channel}".constantize.call!(order: order)
  end

  def self.broadcast_later(order:)
    new(order: order, channel: WEBSOCKET).enqueue
    new(order: order, channel: HTTP).enqueue
  end
end
