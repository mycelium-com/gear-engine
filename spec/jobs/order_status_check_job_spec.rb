require 'rails_helper'

RSpec.describe OrderStatusCheckJob, type: :job do

  let(:order) { create(:order) }

  let(:osc_result_blank) { Interactor::Context.build(final: false) }
  let(:osc_result_changed) { Interactor::Context.build(final: false, order_changed: true) }
  let(:osc_result_final) { Interactor::Context.build(final: true, order_changed: true) }

  let(:of_result_blank) { Interactor::Context.build }
  let(:of_result_changed) { Interactor::Context.build(order_changed: true) }
  
  def expect_order_not_changed
    expect(OrderStatusCheck).to receive(:call).with(order: order).and_return(osc_result_blank)
  end

  def expect_order_changed
    expect(OrderStatusCheck).to receive(:call).with(order: order).and_return(osc_result_changed)
  end

  def expect_order_changed_to_final
    expect(OrderStatusCheck).to receive(:call).with(order: order).and_return(osc_result_final)
  end

  def expect_no_final
    expect(OrderFinalize).not_to receive(:call)
  end

  def expect_final
    expect(OrderFinalize).to receive(:call).with(order: order).and_return(of_result_blank)
  end

  def expect_final_change
    expect(OrderFinalize).to receive(:call).with(order: order).and_return(of_result_changed)
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

    def job_runs
      described_class.perform_now(order: order)
    end

    it "skips finalization and skips callback" do
      expect_order_not_changed
      expect_no_final
      job_runs
      expect_no_callback
    end

    it "skips finalization and does callback" do
      expect_order_changed
      expect_no_final
      job_runs
      expect_callback
    end

    it "does finalization and does callback" do
      expect_order_changed_to_final
      expect_final
      job_runs
      expect_callback
    end

    it "does finalization and does callback" do
      expect_order_changed_to_final
      expect_final_change
      job_runs
      expect_callback
    end
  end

  context "final check" do

    def job_runs
      described_class.perform_now(order: order, final: true)
    end

    it "does finalization and skips callback" do
      expect_order_not_changed
      expect_final
      job_runs
      expect_no_callback
    end

    it "does finalization and does callback" do
      expect_order_not_changed
      expect_final_change
      job_runs
      expect_callback
    end

    it "does finalization and does callback" do
      expect_order_changed
      expect_final
      job_runs
      expect_callback
    end

    it "does finalization and does callback" do
      expect_order_changed
      expect_final_change
      job_runs
      expect_callback
    end

    it "does finalization and does callback" do
      expect_order_changed_to_final
      expect_final
      job_runs
      expect_callback
    end

    it "does finalization and does callback" do
      expect_order_changed_to_final
      expect_final_change
      job_runs
      expect_callback
    end
  end
end
