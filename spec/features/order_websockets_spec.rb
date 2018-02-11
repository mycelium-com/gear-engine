require 'rails_helper'

RSpec.feature "OrderWebsockets" do

  let(:client_page) { "/order-websocket.html##{order.payment_id}" }
  let(:log) { find('#log').text }

  context "new order" do

    let(:order) { create(:order) }

    it "sends order data", js: true do
      visit client_page
      sleep 3
      expect(log).to eq %([websocket.onopen] [websocket.onmessage] #{order.to_json})
    end
  end

  context "paid order" do

    let(:order) { create(:order, :paid) }

    it "sends order data", js: true do
      visit client_page
      sleep 3
      expect(log).to eq %([websocket.onopen] [websocket.onmessage] #{order.to_json})
    end
  end
end
