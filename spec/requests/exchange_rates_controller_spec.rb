require 'rails_helper'

RSpec.describe ExchangeRatesController, type: :controller do

  describe "index action" do

    before do
      VCR.use_cassette('ExchangeRate_update_cache') do
        ExchangeRate.update_cache
      end
    end

    it "returns all data" do
      get :index
      parsed = JSON(response.body)
      expect(parsed.size).to eq ExchangeRate[].size
      expect(parsed.size).to be > 0
    end

    it "converts from->to" do
      get :index, params: { from: :EUR, to: :BTC }
      parsed = JSON(response.body)
      expect(parsed.size).to eq 1
      expect(parsed[0]['src']).to eq 'kraken'

      get :index, params: { from: :UAH, to: :BTC }
      parsed = JSON(response.body)
      expect(parsed.size).to eq 1
      expect(parsed[0]['src']).to eq '1 / (coinbase)'
    end
  end
end
