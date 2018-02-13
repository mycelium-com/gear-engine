require 'rails_helper'

RSpec.describe OrderCallbackHttp, type: :interactor do
  describe '.call' do

    let(:order) { create(:order) }
    let(:result) { described_class.call(order: order) }

    def expect_no_request
      expect(result.request).to eq nil
    end

    def expect_no_response
      expect(result.response).to eq nil
    end

    context "URL is undefined" do

      it "skips callback" do
        expect_no_request
        expect_no_response
        expect(result.success?).to eq true
        expect(order.refresh.callback_response).to be_nil
      end
    end

    context "URL is defined per gateway" do

      def url
        'https://example.com/per-gateway'
      end

      def stubbed_request
        stub_request(:get, "#{url}?#{order.to_http_params}")
      end

      def expect_request
        expect(result.parsed_url).to be_an_instance_of URI::HTTPS
        expect(result.request).to be_an_instance_of Net::HTTP::Get
      end

      def expect_response_of_success
        stubbed_request.to_return(status: 200)
        expect_request
        expect(result.response).to be_an_instance_of Net::HTTPOK
      end

      def expect_response_of_failure
        stubbed_request.to_return(status: 500)
        expect_request
      end

      def expect_response_timeout
        stubbed_request.to_timeout
        expect_request
      end

      before do
        order.gateway.callback_url = url
      end

      it "handles successful callback" do
        expect_response_of_success
        expect(result.success?).to eq true
        expect(order.refresh.callback_response).to eq(code: '200', body: '')
      end

      it "handles failed callback" do
        expect_response_of_failure
        expect(result.success?).to eq false
        expect(result.error).to eq :unexpected_response_code
        expect(order.refresh.callback_response).to eq(code: '500', body: '', error: :unexpected_response_code)
      end

      it "handles timeout" do
        expect_response_timeout
        expect(result.success?).to eq false
        expect(result.error).to eq :timeout
        expect(order.refresh.callback_response).to eq(error: :timeout)
      end

      context "URL has unsupported protocol" do

        def url
          'hpps://meh'
        end

        it "skips callback" do
          expect_no_request
          expect_no_response
          expect(result.success?).to eq false
          expect(result.error).to eq :invalid_url
          expect(order.refresh.callback_response).to eq(error: :invalid_url)
        end
      end

      # FIXME: this may be considered a bug actually
      context "URL has hashbang" do

        def url
          'https://example.com#unexpected'
        end

        it "skips callback" do
          expect_no_request
          expect_no_response
          expect(result.success?).to eq false
          expect(result.error).to eq :invalid_url
          expect(order.refresh.callback_response).to eq(error: :invalid_url)
        end
      end
    end
  end
end
