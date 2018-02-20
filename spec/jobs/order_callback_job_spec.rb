require 'rails_helper'

RSpec.describe OrderCallbackJob, type: :job do

  let(:order) { create(:order) }

  it "has constants for channels" do
    expect(described_class::HTTP).to eq 'Http'
    expect(described_class::WEBSOCKET).to eq 'Websocket'
  end

  it "sends order via HTTP" do
    expect(OrderCallbackHttp).to receive(:call!).with(order: order)
    expect(OrderCallbackWebsocket).not_to receive(:call!)
    described_class.perform_now(order: order, channel: described_class::HTTP)
  end

  it "sends order via Websocket" do
    expect(OrderCallbackWebsocket).to receive(:call!).with(order: order)
    expect(OrderCallbackHttp).not_to receive(:call!)
    described_class.perform_now(order: order, channel: described_class::WEBSOCKET)
  end

  it "sends order via all channels in background" do
    expect {
      described_class.broadcast_later(order: order)
    }.to have_enqueued_job(described_class).exactly(2).times
    expect(described_class).to have_been_enqueued.with(order: order, channel: described_class::HTTP).on_queue('urgent')
    expect(described_class).to have_been_enqueued.with(order: order, channel: described_class::WEBSOCKET).on_queue('urgent')
  end

  it "retries later if failed" do
    expect(OrderCallbackHttp).to receive(:call!).and_raise(StandardError)
    expect {
      described_class.perform_now(order: order, channel: described_class::HTTP)
    }.to have_enqueued_job(described_class).with(order: order, channel: described_class::HTTP).on_queue('default')
  end
end
