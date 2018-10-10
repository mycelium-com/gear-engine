class OrderStatus < EnumerateIt::Base

  associate_values(
    new:          0, # no transactions received
    unconfirmed:  1, # transaction has been received doesn't have enough confirmations yet
    paid:         2, # transaction received with enough confirmations and the correct amount
    underpaid:    3, # amount that was received in a transaction was not enough
    overpaid:     4, # amount that was received in a transaction was too large
    expired:      5, # too much time passed since creating an order
    canceled:     6, # user decides to economize
    partially_paid: -3, # mutable, becomes underpaid or paid/overpaid
  )

  def self.paid?(status)
    status == 2 || status == 4
  end

  def self.immutable?(status)
    status >= 2
  end
end
