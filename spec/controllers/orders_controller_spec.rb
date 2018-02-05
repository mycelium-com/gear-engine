require 'rails_helper'

RSpec.describe OrdersController, type: :controller do

  def expect_order_json(order, json)
    data   = order.to_h
    parsed = JSON(json.to_s)
    parsed.each do |k, v|
      expect(data[k.to_sym]).to eq v
    end
  end

  context "create" do

    let(:params) { build(:params_create_order) }

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

    let(:order) { create(:order) }

    it "shows order" do
      get :show, params: { order_id: order.payment_id }
      expect(response.status).to eq 200
      expect(response).to match_response_schema :order
      expect_order_json order, response.body
    end
  end

  context "websocket" do

    let(:order) { create(:order) }

    it "creates websocket" do
      expect {
        get :websocket, params: { order_id: order.payment_id }
      }.to change { order.gateway.websockets.size }.by 1
    end
  end

  context "cancel" do
  end

  context "invoice" do
  end

  context "reprocess" do
  end
end
