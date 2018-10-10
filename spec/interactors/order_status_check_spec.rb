require 'rails_helper'

RSpec.describe OrderStatusCheck, type: :interactor do
  describe '.call' do

    let(:order) { create(:order, keychain_id: 117) }

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
  end
end
