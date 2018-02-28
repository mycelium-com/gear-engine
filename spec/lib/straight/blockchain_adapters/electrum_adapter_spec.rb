=begin
require 'straight/lib/straight/blockchain_adapters/electrum_adapter'
a = Straight::Blockchain::Electrum.new('tcp://electrumx.adminsehow.com:50001')
a.fetch_transactions_for '1PRqwjFrZMDDNExQE1rbXLNQpNsCGukQwc'

# ssl, rejects self-signed cert
b = Straight::Blockchain::Electrum.new('tcp-tls://electrumx.adminsehow.com:50002')
b.fetch_transactions_for '1PRqwjFrZMDDNExQE1rbXLNQpNsCGukQwc'

# fails to parse segwit transactions
a.fetch_transactions_for '32bT1GaqNaSmTRLUuyW9npzaQTVCmki1T7'
=end

require 'rails_helper'

RSpec.describe Straight::Blockchain::Electrum do

  let(:adapter) { described_class.new(url) }
  let(:cassette_prefix) { "#{url.host}_#{url.port}_#{url.scheme}" }

  describe "#fetch_transactions_for" do

    let(:result) {
      Timecop.freeze('2018-03-01') {
        adapter.fetch_transactions_for(address)
      }
    }

    context "electrumx.adminsehow.com:TCP" do

      let(:url) { URI('tcp://electrumx.adminsehow.com:50001') }

      context "BTC mainnet address with too many transactions" do

        let(:address) { '1DcKsGnjpD38bfj6RMxz945YwohZUTVLby' }

        # anyway, we're not expecting thousands of transactions to single address
        it "fails to fetch transactions" do
          TCR.use_cassette "#{cassette_prefix}_too_many_transactions_for_BTC_mainnet_address" do
            expect { result }.to raise_error(described_class::RequestError)
          end
        end
      end

      context "BTC mainnet address with segwit transactions" do

        let(:address) { '1EDt8oNqgEP356FiAD1SeWJYjXkXgZeJhP' }

        # FIXME: upgrade or replace btcruby gem
        it "fetches transactions but decodes incorrectly" do
          TCR.use_cassette "#{cassette_prefix}_transactions_for_BTC_mainnet_address" do
            expect(result.size).to eq 2
          end
          expect(result[1][:total_amount]).to eq 0
        end
      end
    end
  end
end