require 'rails_helper'

RSpec.describe OrderCallbackWebsocket, type: :interactor do
  describe '.call' do

    let(:order) { create(:order) }

    it "uses ActionCable to broadcast order" do
      expect(ActionCable.server).to receive(:broadcast).with(OrderChannel.order_stream(order), order.to_h)
      described_class.call(order: order)
    end
  end
end
