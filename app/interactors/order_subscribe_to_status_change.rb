class OrderSubscribeToStatusChange
  include Interactor
  include InteractorLogs

  delegate :order, to: :context

  def call
    network = order.gateway.blockchain_network
    BlockbookRealtimeAPI.each_instance(network: network) do |blockbook|
      unsubscribe_addresses = Order.each_final(network, blockbook.each_subscribed_address).map(&:address)
      blockbook.unsubscribe(*unsubscribe_addresses)
      blockbook.subscribe(order.address, &method(:order_status_check))
    end
  end

  # racing against OrderStatusCheckJob and possibly other BlockbookRealtimeAPI instances
  def order_status_check(transactions)
    unsubscribe = false
    result      = nil

    Order.db.transaction do
      order.lock!
      if OrderStatus.immutable?(order.status)
        Rails.logger.debug "Ignoring #{order} with status '#{OrderStatus.key_for(order.status)}'"
        unsubscribe = true
      else
        result = OrderStatusCheck.call(order: order, transactions_since: transactions)
      end
    end

    OrderCallbackJob.broadcast_later(order: order) if result&.order_changed

    :unsubscribe if unsubscribe || result&.final
  end
end
