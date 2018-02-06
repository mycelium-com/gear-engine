require 'rails_helper'

RSpec.describe OrdersController, type: :controller do

  def expect_order_json(order, json)
    data   = order.to_h
    parsed = JSON(json.to_s)
    parsed.each do |k, v|
      expect(data[k.to_sym]).to eq v
    end
  end

  let(:params) { build(:params_create_order) }
  let(:order) { create(:order) }
  let(:order_id) { { order_id: order.payment_id } }

  context "create" do

    it "creates order" do
      expect {
        post :create, params: params
      }.to change { StraightServer::Order.count }.by 1
      expect(response.status).to eq 200
      expect(response).to match_response_schema :order
      order = StraightServer::Order.last
      expect_order_json order, response.body
      expect(order.gateway.hashed_id).to eq params[:gateway_id]
    end
  end

  context "show" do

    it "shows order" do
      get :show, params: order_id
      expect(response.status).to eq 200
      expect(response).to match_response_schema :order
      expect_order_json order, response.body
    end
  end

  context "websocket" do

    it "creates websocket" do
      expect {
        get :websocket, params: order_id
      }.to change { order.gateway.websockets.size }.by 1
    end
  end

  context "cancel" do

    it "cancels new order" do
      expect(order[:status]).to eq 0
      post :cancel, params: order_id
      expect(response.status).to eq 204
      expect(order.reload[:status]).to eq 6
    end
  end

  context "invoice" do

    it "creates BIP70 invoice" do
      get :invoice, params: order_id
      puts response.headers.inspect
      expect(response.headers['Content-Type']).to eq 'application/bitcoin-paymentrequest'
      expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
      expect(response.body).to include 'Payment request for GearPoweredMerchant'
    end
  end
end
