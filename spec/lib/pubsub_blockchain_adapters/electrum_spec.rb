require 'rails_helper'

RSpec.describe 'ElectrumPubSub' do

  it "subscribes to address status changes" do
    Celluloid::Actor[:ElectrumBTC].address_subscribe address: '1PRqwjFrZMDDNExQE1rbXLNQpNsCGukQwc'
  end

  it "converts address to lockscripthash" do
    result = PubSubBlockchainAdapters::ElectrumRootActor.address_to_scripthash('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa')
    expect(result).to eq '8b01df4e368ea28f8dc0423bcf7a4923e3a12d307c875e47a0cfbf90b5c39161'
  end
end