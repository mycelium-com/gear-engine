class OrderStatusCheck
  include Interactor
  include InteractorLogs

  delegate :order, to: :context
  delegate :gateway, to: :order

  def call
    Rails.logger.info { "#{order} [#{self.class.name}] #{order.inspect}" }
    result = order_status
    if result.fetch_values(:status, :amount_paid) != [order.status, order.amount_paid]
      context.order_changed = true
    end
    result.each { |k, v| order.public_send :"#{k}=", v }
    order.save_changed
    context.final = OrderStatus.paid?(order.status)
  end

  def order_status
    uniq_transactions = transactions_since.uniq(&:tid)
    amount_paid       = uniq_transactions.map(&:amount).reduce(:+) || 0

    if !uniq_transactions.empty? && amount_paid <= 0
      Straight.logger.warn "Strange transactions for address #{address}: #{uniq_transactions.inspect}"
      amount_paid = 0
    end

    status =
      if amount_paid > 0
        if (gateway.donation_mode || (amount_paid >= order.amount)) && status_unconfirmed?(uniq_transactions)
          OrderStatus::UNCONFIRMED
        elsif gateway.donation_mode || (amount_paid == order.amount)
          OrderStatus::PAID
        elsif amount_paid < order.amount
          OrderStatus::PARTIALLY_PAID
        elsif amount_paid > order.amount
          OrderStatus::OVERPAID
        end
      else
        OrderStatus::NEW
      end

    {
      status:                status,
      amount_paid:           amount_paid,
      accepted_transactions: uniq_transactions,
    }
  end

  # TODO: fetch only what's needed - https://electrumx.readthedocs.io/en/latest/protocol-methods.html#blockchain-scripthash-history
  def transactions_since
    transactions = BlockchainTransactionsFetch.call!(address: order.address, network: gateway.blockchain_network).transactions
    transactions.select { |t| t.block_height.to_i <= 0 || t.block_height > order.block_height_created_at.to_i }
  end

  def status_unconfirmed?(transactions)
    confirmations = transactions.map { |t| t.confirmations }.map(&:to_i).min
    confirmations < gateway.confirmations_required
  end
end
