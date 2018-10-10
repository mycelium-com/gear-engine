require 'rails_helper'

RSpec.describe ExchangeRate, type: :model do

  def expect_exchange_rate_pair(pair)
    expect(pair.class).to eq ExchangeRate::Pair
    expect(pair.src.class).to eq String
    expect(pair.src).not_to be_empty
    expect(pair.pair.class).to eq Array
    expect(pair.pair.map(&:class).uniq).to eq [Symbol]
    expect(pair.pair.size).to eq 2
    expect(pair.rate.class).to eq BigDecimal
    expect(pair.rate).to be > 0
    expect(pair.time.class).to eq Time
  end

  def update_cache
    VCR.use_cassette('ExchangeRate_update_cache') do
      ExchangeRate.update_cache
    end
  end

  context "cache updated" do

    before do
      update_cache
    end

    it "converts currencies" do
      Currency::BLOCKCHAIN.each do |blockchain_currency|
        Currency::FIAT.each do |price_currency|
          result = ExchangeRate.convert(from: price_currency, to: blockchain_currency)
          expect(result).not_to be_nil, "#{price_currency}->#{blockchain_currency} exchange rate unknown"
          expect_exchange_rate_pair result
          expect(result.pair).to eq Currency[[price_currency, blockchain_currency]]
          Rails.logger.debug "#{price_currency}->#{blockchain_currency} : #{result.src}"
        end
      end
    end

    it "has consistent exchange rates" do
      Currency::BLOCKCHAIN.each do |blockchain_currency|
        Currency::FIAT.each do |price_currency|
          rates = [
            ExchangeRate.convert(from: price_currency, to: blockchain_currency),
            ExchangeRate.convert(from: blockchain_currency, to: price_currency)
          ]
          rates.each(&method(:expect_exchange_rate_pair))
          rate = rates.reduce(:*)
          expect_exchange_rate_pair rate
          expect(rate.rate.round(1)).to(be <= 1, "#{rate} inconsistent")
          Rails.logger.debug "#{price_currency}->#{blockchain_currency}->#{price_currency} : #{rate.src}"
        end
      end
    end
  end
end
