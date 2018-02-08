require 'rails_helper'

RSpec.describe OrderScheduleStatusCheck, type: :interactor do

  describe '.call' do

    let(:order) { create(:order) }

    it "schedules order status checks" do
      result = described_class.call(order: order)
      expect(result.schedule).not_to be_empty
      expect(OrderStatusCheckJob).to have_been_enqueued.exactly(result.schedule.size + 1).times.on_queue('default').with(order)
      result.schedule.each do |time|
        expect(time).to be_instance_of Time
        expect(OrderStatusCheckJob).to have_been_enqueued.at(time)
      end
      result.schedule.each_cons(2) do |(a, b)|
        expect(a).to be < b
      end
      expect(result.schedule.last).to eq(order.created_at + order.gateway.orders_expiration_period)
    end
  end
end
