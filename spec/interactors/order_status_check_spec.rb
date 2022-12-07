require 'rails_helper'

RSpec.describe OrderStatusCheck, type: :interactor do
  describe '.call' do

    let(:order) { create(:order, keychain_id: 117, amount: 1000) }

    it "handles overpaid order" do
      chain = []
      chain << -> {
        Timecop.freeze('2018-09-15') do
          TCR.use_cassette "OrderStatusCheck" do
            @result = described_class.call(order: order)
          end
        end
      }
      chain << -> { expect(&chain[0]).to change { StraightServer::Transaction.count }.by 1 }
      chain << -> { expect(&chain[1]).to change { order.refresh[:status] }.from(0).to(4) }
      chain << -> { expect(&chain[2]).to change { order.refresh[:amount_paid] }.from(nil).to(39479) }
      chain.last.call
      tx = order.accepted_transactions[0]
      expect(tx.amount).to eq order.amount_paid
      expect(tx.tid).to eq 'a96fd9c0f9c0c5b23c911e6341602cb8d7bf7ce56d285be2bfb59b481831bbc9'
      expect(@result.order_changed).to eq true
      expect(@result.final).to eq true
    end

    it "is decoupled from blockchain adapter" do
      expect(BlockchainTransactionsFetch).to_not receive(:call!)

      @result = described_class.call(order: order, transactions_since: [])
      expect(@result.order_changed).to eq true
      order.refresh
      expect(order.status).to eq OrderStatus::NEW
      expect(order.amount_paid).to eq 0

      transactions = [build(:transaction_struct, amount: order.amount / 2)]
      @result      = described_class.call(order: order, transactions_since: transactions)
      expect(@result.order_changed).to eq true
      order.refresh
      expect(order.status).to eq OrderStatus::PARTIALLY_PAID
      expect(order.amount_paid).to eq(order.amount / 2)

      transactions.push(
        build(:transaction_struct, amount: order.amount / 3),
        build(:transaction_struct, amount: order.amount))
      @result = described_class.call(order: order, transactions_since: transactions)
      expect(@result.order_changed).to eq true
      order.refresh
      expect(order.status).to eq OrderStatus::OVERPAID
      expect(order.amount_paid).to eq(order.amount + order.amount / 2 + order.amount / 3)
    end

    it "dedups transactions by id keeping last ones" do
      transactions = [
        build(:transaction_struct, amount: order.amount, tid: 'same', confirmations: 0),
        build(:transaction_struct, amount: order.amount, tid: 'same', confirmations: 3)]
      @result      = described_class.call(order: order, transactions_since: transactions)
      order.refresh
      expect(order.status).to eq OrderStatus::PAID
      expect(order.amount_paid).to eq order.amount
      expect(order.accepted_transactions.size).to eq 1
      expect(order.accepted_transactions.first.confirmations).to eq 3
    end
  end
end
