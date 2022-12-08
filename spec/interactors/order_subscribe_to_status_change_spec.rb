require 'rails_helper'

RSpec.describe OrderSubscribeToStatusChange, type: :interactor do
  describe '.call' do

    let(:gateway) { create(:gateway) }
    let(:order) { create(:order, gateway: gateway) }
    let(:order2) { create(:order, gateway: gateway) }
    let(:order3) { create(:order, gateway: gateway) }

    before do
      ENV['BLOCKBOOK_BTC_WS']               = 'wss://bb-btc.mycelium.com:9130/websocket'
      ENV['BLOCKBOOK_BTC_TEST_WS']          = 'wss://bb-btc.mycelium.com:19130/websocket'
      Thread.current[:BlockbookRealtimeAPI] = nil
    end

    it "uses BlockbookRealtimeAPI" do
      subscribed = -> { BlockbookRealtimeAPI.each_instance(network: gateway.blockchain_network).map(&:each_subscribed_address).map(&:to_a) }
      expect(subscribed.call).to eq [[]]

      described_class.call(order: order)
      expect(subscribed.call).to eq [[order.address]]
      described_class.call(order: order2)
      expect(subscribed.call).to eq [[order.address, order2.address]]

      order.status = OrderStatus::CANCELED
      order.save_changed

      # it prunes existing subscriptions for immutable orders
      described_class.call(order: order3)
      expect(subscribed.call).to eq [[order2.address, order3.address]]
    end
  end

  describe 'order_status_check' do

    let(:order) { create(:order) }
    let(:described_instance) { described_class.new(order: order) }
    let(:transactions) { ['whatever'] }

    let(:osc_result_blank) { Interactor::Context.build(final: false) }
    let(:osc_result_changed) { Interactor::Context.build(final: false, order_changed: true) }
    let(:osc_result_final) { Interactor::Context.build(final: true, order_changed: true) }

    def expect_no_status_check
      expect(OrderStatusCheck).not_to receive(:call)
    end

    def expect_order_not_changed
      expect(OrderStatusCheck).to receive(:call).with(order: order, transactions_since: transactions).and_return(osc_result_blank)
    end

    def expect_order_changed
      expect(OrderStatusCheck).to receive(:call).with(order: order, transactions_since: transactions).and_return(osc_result_changed)
    end

    def expect_order_changed_to_final
      expect(OrderStatusCheck).to receive(:call).with(order: order, transactions_since: transactions).and_return(osc_result_final)
    end

    def expect_no_final
      expect(OrderStatusFinalize).not_to receive(:call)
    end

    def expect_no_callback
      expect(OrderCallbackJob).not_to have_been_enqueued
    end

    def expect_callback
      expect(OrderCallbackJob).to have_been_enqueued.exactly(2).times
      expect(OrderCallbackJob).to have_been_enqueued.with(order: order, channel: OrderCallbackJob::WEBSOCKET)
      expect(OrderCallbackJob).to have_been_enqueued.with(order: order, channel: OrderCallbackJob::HTTP)
    end

    context "regular check" do

      it "expects more, skips callback, skips finalization" do
        expect_order_not_changed
        expect_no_final
        @result = described_instance.order_status_check(transactions)
        expect(@result).to be_nil
        expect_no_callback
      end

      it "expects more, does callback, skips finalization (expiration handled by OrderStatusCheckJob)" do
        expect_order_changed
        expect_no_final
        @result = described_instance.order_status_check(transactions)
        expect(@result).to be_nil
        expect_callback
      end

      it "doesn't expect more, does callback, skips finalization (OrderStatusFinalize does nothing for immutable order)" do
        expect_order_changed_to_final
        expect_no_final
        @result = described_instance.order_status_check(transactions)
        expect(@result).to eq :unsubscribe
        expect_callback
      end
    end

    context "finalized order" do

      before do
        order.update(status: OrderStatus::CANCELED)
      end

      it "doesn't expect more, skips everything" do
        expect_no_status_check
        expect_no_final
        @result = described_instance.order_status_check(transactions)
        expect(@result).to eq :unsubscribe
        expect_no_callback
      end
    end
  end
end
