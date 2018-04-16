require 'rails_helper'

def expect_order_json(order, json)
  expect(json).to be_kind_of String
  expect(json).to match_response_schema :order
  data   = order.to_h
  parsed = JSON(json)
  parsed.each do |k, v|
    expect(data[k.to_sym]).to eq v
  end
end

def expect_order_create(&block)
  expect(&block).to change { StraightServer::Order.count }.by 1
  expect(response.status).to eq 200
  order = StraightServer::Order.last
  expect_order_json order, response.body
  order
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
  expect(response.status).to eq 204
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
  expect(response.body).to eq "X-Signature is invalid"
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

RSpec.shared_examples "order create action" do |payment:, price:, rate:|

  let(:gateway) { create(:gateway, default_currency: payment.to_s, exchange_rate_adapter_names: [rate.to_s]) }

  it "creates order with #{price}->#{payment} conversion via #{rate}+Fixer" do
    order =
        VCR.use_cassette "order_create_#{price}_#{payment}_#{rate}" do
          expect_order_create do
            post url, params: build(:params_create_order, currency: price.to_s)
          end
        end
    expect(order.amount_with_currency).to eq "1.00 #{price}"
  end
end


RSpec.describe OrdersController, type: :request do

  let(:order_id) { { order_id: order.payment_id } }
  let(:gateway_order_id) { { gateway_id: order.gateway.hashed_id, order_id: order.payment_id } }
  let(:legacy_order_id) { { order_id: order.id } }
  let(:legacy_gateway_order_id) { { gateway_id: order.gateway.hashed_id, order_id: order.id } }

  context "gateway without signature checking" do

    let(:gateway) { create(:gateway) }
    let(:order) { create(:order, gateway: gateway) }

    describe "create action" do

      let(:url) { gateway_orders_path(gateway_id: gateway.hashed_id) }

      it "creates order" do
        expect_order_create do
          post url, params: build(:params_create_order)
        end
      end

      it "creates any-amount-accepted order" do
        expect_order_create do
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

      it "returns 409 and error message when amount is negative" do
        expect {
          post url, params: build(:params_create_order, :negative_amount)
        }.to change { StraightServer::Order.count }.by 0
        expect(response.status).to eq 409
        expect(response.body).to eq "Invalid order: amount cannot be nil or less than 0"
      end

      it "returns 503 and error message when gateway is inactive" do
        gateway = create(:gateway, active: false)
        expect {
          post gateway_orders_path(gateway_id: gateway.hashed_id), params: build(:params_create_order)
        }.to change { StraightServer::Order.count }.by 0
        expect(response.status).to eq 503
        expect(response.body).to eq "The gateway is inactive, you cannot create order with it"
      end

      it "returns 404 and error message when gateway is not found" do
        expect {
          post gateway_orders_path(gateway_id: 'nonexistent'), params: build(:params_create_order)
        }.to change { StraightServer::Order.count }.by 0
        expect(response.status).to eq 404
        expect(response.body).to eq "Gateway not found"
      end

      context "price in local currency" do
        %w[USD EUR JPY GBP AUD CAD CHF CNY MXN SEK UAH RUB].each do |price_currency|
          context price_currency do
            %w[Bitpay Bitstamp Coinbase Kraken Okcoin].each do |rate|
              next if 'UAH' == price_currency && %w[Bitstamp Kraken Okcoin].include?(rate)
              it_behaves_like "order create action", payment: 'BTC', price: price_currency, rate: rate
            end
          end
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

  context "gateway with signature checking" do

    let(:gateway) { create(:gateway, :with_auth) }
    let(:order) { create(:order, gateway: gateway) }
    let(:signature_header) { {
        'X-Signature' => StraightServer::SignatureValidator.signature(**signature_params)
    } }
    let(:signature_header_hex) { {
        'X-Signature' => StraightServer::SignatureValidator.signature2(**signature_params)
    } }
    let(:invalid_signature_header) { {
        'X-Signature' => 'blablabla'
    } }
    let(:signature_params) { {
        body:        params.to_param,
        method:      request_method,
        request_uri: url,
        secret:      gateway.secret
    } }

    describe "create action" do

      let(:url) { "/gateways/#{gateway.hashed_id}/orders" }
      let(:request_method) { 'POST' }
      let(:params) { build(:params_create_order) }

      it "does not create order without signature" do
        expect {
          post url, params: params
        }.to change { StraightServer::Order.count }.by 0
        expect_request_unauthorized
      end

      it "does not create order with invalid signature" do
        expect {
          post url, params: params, headers: invalid_signature_header
        }.to change { StraightServer::Order.count }.by 0
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