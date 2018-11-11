require 'rails_helper'

RSpec.describe ExchangeRateCacheUpdateJob, type: :job do

  it "updates exchange rate cache" do
    expect(ExchangeRate).to receive(:update_cache)
    described_class.perform_now
  end

  it "uses default queue" do
    expect {
      described_class.perform_later
    }.to have_enqueued_job(described_class).on_queue('default')
  end
end