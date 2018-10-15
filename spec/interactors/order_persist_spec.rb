require 'rails_helper'

RSpec.describe OrderPersist, type: :interactor do
  describe '.call' do

    let(:gateway) { create(:gateway) }

    it "creates order with amount after currency exchange" do
      params = OrderParamsValidate.call!(
        gateway: gateway, params: build(:params_create_order, :USD, amount: 2)
      )
      expect(ExchangeRate).to receive(:convert).with(from: :USD, to: :BTC).and_return(
        ExchangeRate::Pair.new(rate: 0.00021.to_d, pair: %i[USD BTC], src: 'spec', time: Time.now)
      )
      order = OrderPersist.call!(params).order
      expect(order.amount).to eq 42000 # Satoshi
      expect(order.amount_with_currency).to eq "2.00 USD"
    end
  end
end
