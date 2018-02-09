require 'rails_helper'

RSpec.describe OrderStatusCheckJob, type: :job do

  let(:order) { :order }

  it "checks order status" do
    expect(OrderStatusCheck).to receive(:call).with(order: order)
    expect(OrderFinalize).not_to receive(:call)
    described_class.perform_now(order: order)
  end

  it "checks order final status" do
    expect(OrderStatusCheck).to receive(:call).with(order: order)
    expect(OrderFinalize).to receive(:call).with(order: order)
    described_class.perform_now(order: order, final: true)
  end
end
