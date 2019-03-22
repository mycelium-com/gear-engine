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

RSpec.describe ElectrumAPI do

  let(:adapter) { described_class.new(url: url) }
  let(:cassette_prefix) { "ElectrumAPI_#{network}_#{url.host}-#{url.port}" }

  it "converts address to lockscripthash" do
    result = ElectrumAPI.address_to_scripthash('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa')
    expect(result).to eq '8b01df4e368ea28f8dc0423bcf7a4923e3a12d307c875e47a0cfbf90b5c39161'
  end

  describe "#fetch_transactions_for" do

    let(:result) {
      Timecop.freeze('2018-03-01') {
        adapter.fetch_transactions_for(address)
      }
    }

    context "BTC" do

      let(:network) { BlockchainNetwork::BTC }
      let(:url) { Rails.application.config.blockchain_adapters[network].first.url }

      context "BTC mainnet address with too many transactions" do

        let(:address) { '1DcKsGnjpD38bfj6RMxz945YwohZUTVLby' }

        # anyway, we're not expecting thousands of transactions to single address
        it "fails to fetch transactions" do
          TCR.use_cassette "#{cassette_prefix}_#{address}_too_many_transactions" do
            expect { result }.to raise_error(RuntimeError)
          end
        end
      end

      context "BTC mainnet address with segwit transactions" do

        let(:address) { '1EDt8oNqgEP356FiAD1SeWJYjXkXgZeJhP' }

        it "fetches transactions and decodes correctly" do
          TCR.use_cassette "#{cassette_prefix}_transactions_for_BTC_mainnet_address" do
            expect(result[1][:amount]).to eq 1999706
          end
        end
      end
    end
  end
end