require 'rails_helper'

RSpec.describe OrdersController, type: :controller do

  def expect_order_json(order, json)
    expect(json).to be_kind_of String
    expect(json).to match_response_schema :order
    data   = order.to_h
    parsed = JSON(json)
    parsed.each do |k, v|
      expect(data[k.to_sym]).to eq v
    end
  end

  def expect_order_created(params)
    expect(params[:gateway_id]).to be_present
    expect {
      post :create, params: params
    }.to change { StraightServer::Order.count }.by 1
    expect(response.status).to eq 200
    order = StraightServer::Order.last
    expect_order_json order, response.body
    expect(order.gateway.hashed_id).to eq params[:gateway_id]
    order
  end

  let(:order) { create(:order) }
  let(:order_id) { { order_id: order.payment_id } }

  context "create" do

    it "creates order" do
      expect_order_created build(:params_create_order)
    end

    it "creates any-amount-accepted order" do
      expect_order_created build(:params_create_order, :no_amount)
    end

    it "saves data and callback_data params" do
      params = build(:params_create_order, :with_data, :with_callback_data)
      order  = expect_order_created(params)
      expect(order.data['hello']).to eq 'world'
      expect(order.callback_data).to eq 'some random data'
    end

    it "returns 409 and error message when amount is negative" do
      expect {
        post :create, params: build(:params_create_order, :negative_amount)
      }.to change { StraightServer::Order.count }.by 0
      expect(response.status).to eq 409
      expect(response.body).to eq "Invalid order: amount cannot be nil or less than 0"
    end

    it "returns 503 and error message when gateway is inactive" do
      gateway = create(:gateway, active: false)
      expect {
        post :create, params: build(:params_create_order, gateway_id: gateway.hashed_id)
      }.to change { StraightServer::Order.count }.by 0
      expect(response.status).to eq 503
      expect(response.body).to eq "The gateway is inactive, you cannot create order with it"
    end

    it "returns 404 and error message when gateway is not found" do
      expect {
        post :create, params: build(:params_create_order, gateway_id: 'nonexistent')
      }.to change { StraightServer::Order.count }.by 0
      expect(response.status).to eq 404
      expect(response.body).to eq "Gateway not found"
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
