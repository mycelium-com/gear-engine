require 'rails_helper'

RSpec.describe OrderScheduleStatusCheck, type: :interactor do

  describe '.call' do

    let(:order) { create(:order) }

    it "schedules order status checks" do
      result = described_class.call(order: order)
      expect(result.schedule).not_to be_empty
      expect(OrderStatusCheckJob).to have_been_enqueued.exactly(result.schedule.size + 1).times.on_queue('default')
      result.schedule.each_with_index do |time, i|
        final = result.schedule.size == i + 1
        expect(time).to be_instance_of Time
        expect(OrderStatusCheckJob).to have_been_enqueued.at(time).with(order: order, final: final)
      end
      prev_interval = 0
      intervals = result.schedule.each_cons(2)
      intervals.each_with_index do |(a, b), i|
        expect(a).to be < b
        if i + 1 != intervals.size # last check ignores backoff
          expect(b - a).to be >= prev_interval
        end
        prev_interval = b - a
      end
      expect(result.schedule.last).to eq(order.created_at + order.gateway.orders_expiration_period)
    end

    it "is configurable via ENV vars" do
      ENV['ORDER_CHECK_BASE_INTERVAL'] = '1'
      ENV['ORDER_CHECK_MAX_INTERVAL']  = '1'
      ENV['ORDER_CHECK_BACKOFF_MULT']  = '1.0'
      ENV['ORDER_CHECK_RAND_FACTOR']   = '0.0'
      result = described_class.call(order: order)
      expect(result.schedule.size).to eq(300)

      ENV['ORDER_CHECK_BASE_INTERVAL'] = '3'
      ENV['ORDER_CHECK_MAX_INTERVAL']  = '3'
      ENV['ORDER_CHECK_BACKOFF_MULT']  = '1.0'
      ENV['ORDER_CHECK_RAND_FACTOR']   = '0.0'
      result = described_class.call(order: order)
      expect(result.schedule.size).to eq(100)

      # the new defaults
      ENV['ORDER_CHECK_BASE_INTERVAL'] = '3'
      ENV['ORDER_CHECK_MAX_INTERVAL']  = '600'
      ENV['ORDER_CHECK_BACKOFF_MULT']  = '1.0027'
      ENV['ORDER_CHECK_RAND_FACTOR']   = '0.0'

      order.gateway.orders_expiration_period = 900
      order.gateway.save_changed
      result = described_class.call(order: order)
      expect(result.schedule.size).to eq(221)

      order.gateway.orders_expiration_period = 48 * 3600
      order.gateway.save_changed
      result = described_class.call(order: order)
      expect(result.schedule.size).to eq(1875)
      # puts result.schedule.inspect
    end
  end
end
