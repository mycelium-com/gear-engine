require 'rails_helper'

RSpec.shared_examples "blockchain transactions fetch" do |address:, network:|
  it "fetches transactions for #{network} address" do
    TCR.use_cassette "BlockchainTransactionsFetch_#{network}_#{address}" do
      Timecop.freeze('2018-09-15') do
        result = described_class.call!(address: address, network: network)
        expect(result.transactions.map(&:class).uniq).to eq [Straight::Transaction]
      end
    end
  end
end

RSpec.describe BlockchainTransactionsFetch, type: :interactor do

  describe '.call' do
    include_examples "blockchain transactions fetch",
                     address: '15rtz6Xrt4cBwMHa5D1t9NQqCnktubb84t',
                     network: BlockchainNetwork::BTC
    include_examples "blockchain transactions fetch",
                     address: 'mwj4uqUYqdJcDj2byxF5xV9pbvmTdkBF5c',
                     network: BlockchainNetwork::BTC_TEST
    # include_examples "blockchain transactions fetch",
    #                 address: '1MUALS11V4SrXa2Dz5xZMYyW8Fyzy9Sj4w',
    #                 network: BlockchainNetwork::BCH
    # include_examples "blockchain transactions fetch",
    #                 address: 'mo8WkAVuD4zpmBQTQqZZAx7Ch4nEipMpn3',
    #                 network: BlockchainNetwork::BCH_TEST
  end

  it "detects exact amount" do
    network = BlockchainNetwork::BTC_TEST
    address = 'mj4gJrEFTDjeJUEY4GxcAMv4NfUaVFJkas'
    TCR.use_cassette "BlockchainTransactionsFetch_#{network}_#{address}" do
      result = described_class.call!(address: address, network: network)
      expect(result.transactions[0].amount).to eq 60000
    end
  end
end

