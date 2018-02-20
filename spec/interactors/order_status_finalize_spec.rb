require 'rails_helper'

RSpec.describe OrderStatusFinalize, type: :interactor do
  describe '.call' do

    it "changes new to expired" do
      order = create(:order)
      expect {
        result = described_class.call(order: order)
        expect(result.order_changed).to eq true
      }.to change { order.status }.from(0).to(5)
    end

    it "changes partially paid to underpaid" do
      order = create(:order, :partially_paid)
      expect {
        result = described_class.call(order: order)
        expect(result.order_changed).to eq true
      }.to change { order.status }.from(-3).to(3)
    end

    it "does not change unconfirmed" do
      order = create(:order, :unconfirmed)
      expect {
        result = described_class.call(order: order)
        expect(result.order_changed).to be_nil
      }.not_to change { order.status }
    end
  end
end
