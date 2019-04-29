require 'rails_helper'

def expect_order_json(order, json)
  expect(json).to be_kind_of String
  expect(json).to match_response_schema :order
  data   = order.to_h
  parsed = JSON(json)
  parsed.each do |k, v|
    expect(data[k.to_sym]).to (eq v), "order.#{k} doesn't match\nexpected #{data[k.to_sym]}, got: #{parsed[k]}"
  end
end

def expect_order_create(&block)
  expect(&block).to change { Order.orm.count }.by 1
  expect(response.status).to eq 200
  order = Order.find_by({})
  expect_order_json order, response.body
  order
end

def expect_order_invalid(&block)
  expect(&block).not_to(change { Order.orm.count })
  expect(response.status).to eq 422
end

def expect_order_show
  yield
  expect(response.status).to eq 200
  expect(response).to match_response_schema :order
  expect_order_json order, response.body
end

def expect_order_cancel
  expect(order[:status]).to eq 0
  yield
  expect(response.status).to eq 200
  expect(order.reload[:status]).to eq 6
end

def expect_order_invoice
  yield
  expect(response.headers['Content-Type']).to eq 'application/bitcoin-paymentrequest'
  expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
  expect(response.body).to include 'Payment request for GearPoweredMerchant'
end

def expect_request_unauthorized
  expect(response.status).to eq 401
  expect(response.body).to eq %({"error":"X-Signature is invalid"})
end

RSpec.shared_examples "order actions" do

  describe "show action" do
    it "shows order" do
      expect_order_show do
        get show_path
      end
    end

    it "shows order by id" do
      expect_order_show do
        get legacy_show_path
      end
    end
  end

  describe "cancel action" do
    it "cancels new order" do
      expect_order_cancel do
        post cancel_path
      end
    end
  end

  describe "invoice action" do
    it "creates BIP70 invoice" do
      expect_order_invoice do
        get invoice_path
      end
    end
  end
end

RSpec.shared_examples "order signed actions" do

  let(:params) { {} }

  describe "show action" do

    let(:url) { show_path }
    let(:request_method) { 'GET' }

    it "does not show order without signature" do
      get url
      expect_request_unauthorized
    end

    it "shows order" do
      expect_order_show do
        get url, params: params, headers: signature_header
      end
    end
  end

  describe "legacy show action" do

    let(:url) { legacy_show_path }
    let(:request_method) { 'GET' }

    it "does not show order without signature" do
      get url
      expect_request_unauthorized
    end

    it "shows order" do
      expect_order_show do
        get url, params: params, headers: signature_header
      end
    end
  end

  describe "cancel action" do

    let(:url) { cancel_path }
    let(:request_method) { 'POST' }

    it "does not cancel new order without signature" do
      post url
      expect_request_unauthorized
      expect(order.reload[:status]).to eq 0
    end

    it "cancels new order" do
      expect_order_cancel do
        post url, params: params, headers: signature_header
      end
    end
  end

  describe "invoice action" do

    it "creates BIP70 invoice without signature" do
      expect_order_invoice do
        get invoice_path
      end
    end
  end
end

RSpec.shared_examples "order create action" do |price_currency:|

  # parent context: gateway, url

  it "creates order with amount in #{price_currency}" do
    # TODO: maybe speed up by keeping this cache
    VCR.use_cassette('ExchangeRate_update_cache') do
      ExchangeRate.update_cache
    end
    order =
      VCR.use_cassette "order_create_#{price_currency}_#{gateway.blockchain_currency}" do
        expect_order_create do
          post url, params: build(:params_create_order, currency: price_currency.to_s)
        end
      end
    expect(order.amount_with_currency).to eq "1.00 #{price_currency}"
  end
end

RSpec.shared_examples "gateway without signature checking" do

  # parent context: gateway
  let(:order) { create(:order, gateway: gateway) }

  describe "create action" do

    let(:url) { gateway_orders_path(gateway_id: gateway.hashed_id) }

    it "creates order" do
      expect_order_create do
        post url, params: build(:params_create_order)
      end
    end

    it "does not create any-amount-accepted order" do
      expect_order_invalid do
        post url, params: build(:params_create_order, :no_amount)
      end
    end

    it "saves data and callback_data params" do
      order = expect_order_create do
        post url, params: build(:params_create_order, :with_data, :with_callback_data)
      end
      expect(order.data['hello']).to eq 'world'
      expect(order.callback_data).to eq 'some random data'
    end

    it "returns 422 and error message when amount is negative" do
      expect {
        post url, params: build(:params_create_order, :negative_amount)
      }.to change { Order.orm.count }.by 0
      expect(response.status).to eq 422
      expect(response.body).to eq %({"error":{"amount":["must be greater than 0"]}})
    end

    it "returns 403 and error message when gateway is inactive" do
      gateway = create(:gateway, active: false)
      expect {
        post gateway_orders_path(gateway_id: gateway.hashed_id), params: build(:params_create_order)
      }.to change { Order.orm.count }.by 0
      expect(response.status).to eq 403
      expect(response.body).to eq %({"error":"This gateway is inactive"})
    end

    it "returns 404 and error message when gateway is not found" do
      expect {
        post gateway_orders_path(gateway_id: 'nonexistent'), params: build(:params_create_order)
      }.to change { Order.orm.count }.by 0
      expect(response.status).to eq 404
      expect(response.body).to eq %({"error":"Gateway not found"})
    end

    context "price in local currency" do
      Currency::FIAT.each do |price_currency|
        include_examples"order create action", price_currency: price_currency
      end
    end
  end

  context "short URLs" do

    let(:legacy_show_path) { order_path(legacy_order_id) }
    let(:show_path) { order_path(order_id) }
    let(:cancel_path) { order_cancel_path(order_id) }
    let(:invoice_path) { order_invoice_path(order_id) }

    it_behaves_like "order actions"
  end

  context "legacy URLs" do

    let(:legacy_show_path) { gateway_order_path(legacy_gateway_order_id) }
    let(:show_path) { gateway_order_path(gateway_order_id) }
    let(:cancel_path) { gateway_order_cancel_path(gateway_order_id) }
    let(:invoice_path) { gateway_order_invoice_path(gateway_order_id) }

    it_behaves_like "order actions"
  end
end


RSpec.describe OrdersController, type: :request do

  let(:order_id) { { order_id: order.payment_id } }
  let(:gateway_order_id) { { gateway_id: order.gateway.hashed_id, order_id: order.payment_id } }
  let(:legacy_order_id) { { order_id: order.id } }
  let(:legacy_gateway_order_id) { { gateway_id: order.gateway.hashed_id, order_id: order.id } }

  context "BTC gateway" do
    let(:gateway) { create(:gateway) }
    it_behaves_like "gateway without signature checking"
  end

  context "BCH gateway" do
    let(:gateway) { create(:gateway, :BCH) }
    it_behaves_like "gateway without signature checking"
  end

  context "BTC gateway with signature checking" do

    let(:gateway) { create(:gateway, :with_auth) }
    let(:order) { create(:order, gateway: gateway) }
    let(:request_nonce) { 1442214027577 }
    let(:signature_header) { {
      'X-Signature' => StraightServer::SignatureValidator.signature(**signature_params)
    } }
    let(:signature_header_hex) { {
      'X-Signature' => StraightServer::SignatureValidator.signature2(**signature_params)
    } }
    let(:invalid_signature_header) { {
      'X-Signature' => 'blablabla'
    } }
    let(:signature_header_with_nonce) { {
      'X-Nonce' => request_nonce,
      'X-Signature' => StraightServer::SignatureValidator.signature(**signature_params_with_nonce)
    } }
    let(:signature_params) { {
      body:        params.to_param,
      method:      request_method,
      request_uri: url,
      secret:      gateway.secret
    } }
    let(:signature_params_with_nonce) {
      signature_params.merge(nonce: request_nonce)
    }

    describe "create action" do

      let(:url) { "/gateways/#{gateway.hashed_id}/orders" }
      let(:request_method) { 'POST' }
      let(:params) { build(:params_create_order) }

      it "does not create order without signature" do
        expect {
          post url, params: params
        }.to change { Order.orm.count }.by 0
        expect_request_unauthorized
      end

      it "does not create order with invalid signature" do
        expect {
          post url, params: params, headers: invalid_signature_header
        }.to change { Order.orm.count }.by 0
        expect_request_unauthorized
      end

      it "creates order" do
        expect_order_create do
          post url, params: params, headers: signature_header
        end
      end

      it "creates order" do
        expect_order_create do
          post url, params: params, headers: signature_header_hex
        end
      end

      it "creates order with nonce in signature" do
        expect_order_create do
          post url, params: params, headers: signature_header_with_nonce
        end
      end
    end

    context "short URLs" do

      let(:legacy_show_path) { order_path(legacy_order_id) }
      let(:show_path) { order_path(order_id) }
      let(:cancel_path) { order_cancel_path(order_id) }
      let(:invoice_path) { order_invoice_path(order_id) }

      it_behaves_like "order signed actions"
    end

    context "legacy URLs" do

      let(:legacy_show_path) { gateway_order_path(legacy_gateway_order_id) }
      let(:show_path) { gateway_order_path(gateway_order_id) }
      let(:cancel_path) { gateway_order_cancel_path(gateway_order_id) }
      let(:invoice_path) { gateway_order_invoice_path(gateway_order_id) }

      it_behaves_like "order signed actions"
    end
  end
end
