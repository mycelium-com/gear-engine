require 'rails_helper'

RSpec.describe BlockbookRealtimeAPI do

  let(:instance) { described_class.instance(url: 'wss://bb-btc.mycelium.com:19130/websocket', network: :BTC_TEST) }
  let(:instance_conn_spy) do
    result = described_class.instance(url: 'wss://bb-btc.mycelium.com:19130/websocket', network: :BTC_TEST)
    result.instance_variable_set(:@connection, spy(:iodine_conn))
    result
  end

  before do
    ENV['BLOCKBOOK_BTC_WS']               = 'wss://bb-btc.mycelium.com:9130/websocket'
    ENV['BLOCKBOOK_BTC_TEST_WS']          = 'wss://bb-btc.mycelium.com:19130/websocket'
    Thread.current[:BlockbookRealtimeAPI] = nil
  end

  def expect_connection(times=1)
    expect(Iodine).to receive(:connect).and_return(:whatever).exactly(times).times
  end

  describe 'new' do
    it "is private" do
      expect { BlockbookRealtimeAPI.new(url: '', network: '') }.to raise_error(NoMethodError)
    end
  end

  describe 'instance' do

    let(:url) { 'wss://example.invalid/websocket' }

    it "is per-thread singleton" do
      expect_connection
      @result = [
        described_class.instance(url: url, network: :BTC),
        described_class.instance(url: url, network: :BTC),
        described_class.instance(url: url, network: :BTC)
      ]
      expect(@result.map(&:object_id).uniq.size).to eq 1

      # @registry = described_class.send(:registry)
      # expect(@registry.size).to eq 1
      # expect(@registry).to eq([:BTC, url] => @result[0])
      # expect(@registry.object_id).to eq Thread.current[:BlockbookRealtimeAPI].object_id
    end

    it "validates params" do
      expect(Iodine).not_to receive(:connect)
      expect { described_class.instance(url: nil, network: :BTC) }.to raise_error(ArgumentError)
      expect { described_class.instance(url: '', network: :BTC) }.to raise_error(ArgumentError)
      expect { described_class.instance(url: "\n", network: :BTC) }.to raise_error(ArgumentError)
      expect { described_class.instance(url: '1 2', network: :BTC) }.to raise_error(URI::InvalidURIError)
      expect { described_class.instance(url: url, network: :WTF) }.to raise_error(NameError)
    end
  end

  describe 'each_instance' do

    it "initializes each instance" do
      expect_connection 2
      @result = described_class.each_instance
      expect(@result).to be_kind_of Enumerator
      expect(@result.size).to eq 2
      expect(@result.map(&:object_id).uniq.size).to eq 2
      @result.each do |e|
        expect(ENV.fetch("BLOCKBOOK_#{e.network}_WS").split(',')).to include(e.url)
      end

      @result2 = []
      described_class.each_instance do |e|
        @result2 << e
      end
      expect(@result2.map(&:object_id)).to eq @result.map(&:object_id)
    end

    it "allows filtering by network" do
      expect_connection 2
      @result = described_class.each_instance(network: :BTC).to_a
      expect(@result.size).to eq 1
      expect(@result.first.network).to eq BlockchainNetwork[:BTC]
    end

    it "supports mulptiple servers per network" do
      expect_connection 4
      ENV['BLOCKBOOK_BTC_WS'] = urls = 'wss://b.invalid,wss://a.invalid,wss://c.invalid'

      @result = described_class.each_instance(network: :BTC).to_a
      expect(@result.size).to eq 3
      expect(@result.map(&:url)).to eq urls.split(',')
    end
  end

  describe 'on_open' do
    it "triggers queued requests" do
      expect_connection
      expect(instance.connection).to be_nil
      instance.subscribe('test1')
      instance.subscribe('test2')
      expected_queue = [
        %({"id":"","method":"subscribeAddresses","params":{"addresses":["test1"]}}\n),
        %({"id":"","method":"subscribeAddresses","params":{"addresses":["test1","test2"]}}\n)
      ]
      expect(instance.requests_queue).to eq expected_queue
      fake_conn = spy(:iodine_conn)
      expect(fake_conn).to receive(:write).with(expected_queue[0]).ordered
      expect(fake_conn).to receive(:write).with(expected_queue[1]).ordered

      instance.on_open(fake_conn)

      expect(instance.connection).to equal fake_conn
      expect(instance.requests_queue).to eq []
    end
  end

  describe 'on_message' do

    let(:address) { 'tb1qfj93v49vtwrhhtdflvejczhpdncn7fcsffpnv2' }
    let(:message) { %({"data":{"address":"tb1qfj93v49vtwrhhtdflvejczhpdncn7fcsffpnv2", "tx":{"txid":"82203c42f81d02ea4e16824dc5a10c476234a8ae85a79d3923e8e842437387e9", "version":1, "vin":[{"txid":"da863dbe4b981ca81868110a58f1132eb39224e6aa4eb79e045aa249c5182686", "vout":1, "sequence":4294967293, "n":0, "addresses":["tb1q2cwwaxhsd6vcx92nazrla5hwzszjepulauxqwq"], "isAddress":true, "value":"10966715577"}], "vout":[{"value":"10000", "n":0, "hex":"00144c8b1654ac5b877bada9fb332c0ae16cf13f2710", "addresses":["tb1qfj93v49vtwrhhtdflvejczhpdncn7fcsffpnv2"], "isAddress":true}, {"value":"10966705436", "n":1, "hex":"001496a6b5f33fc0c3d1b9bb37b979b2b7f42405cf22", "addresses":["tb1qj6nttuelcrparwdmx7uhnv4h7sjqtnezvx5mxe"], "isAddress":true}], "blockHeight":0, "confirmations":0, "blockTime":1669909454, "value":"10966715436", "valueIn":"10966715577", "fees":"141", "hex":"01000000000101862618c549a25a049eb74eaae62492b32e13f1580a116818a81c984bbe3d86da0100000000fdffffff0210270000000000001600144c8b1654ac5b877bada9fb332c0ae16cf13f27101ca5aa8d0200000016001496a6b5f33fc0c3d1b9bb37b979b2b7f42405cf220247304402205b594ca11b7a042d7383692716369f04c15462ca514d435b250af68547e3b9f702207f35e7a6451f4365d5570dd8fde2a2e8148c0a8f5a2134afe17ddea2636296b701210368f3ea13c44326f6c47f861f6be85fa6f5cd8503aaa7c996af26e57acbf1af2000000000", "rbf":true}}}) }
    let(:message_tx_id) { %(82203c42f81d02ea4e16824dc5a10c476234a8ae85a79d3923e8e842437387e9) }
    let(:message_tx_value) { 10000 }

    it "triggers subscription callback" do
      expect_connection
      callback  = -> (transactions) {
        expect(transactions).to be_kind_of Array
        expect(transactions.size).to eq 1
        tx = transactions.first
        expect(tx).to be_kind_of Straight::Transaction
        expect(tx.tid).to eq message_tx_id
        expect(tx.amount).to eq message_tx_value
        expect(tx.block_height).to eq 0
        expect(tx.confirmations).to eq 42
      }
      expect(callback).to receive(:call).exactly(1).times
      instance.subscribe(address, &callback)
      instance.on_message(:whatever_conn, message)
    end
  end

  describe 'on_close' do
    it "reconnects and resubscribes" do
      expect_connection 2
      instance = instance_conn_spy
      fake_conn = instance.connection
      expect(fake_conn.nil?).to eq false
      expect(fake_conn).to receive(:close).exactly(1).times
      expect(fake_conn).to receive(:open?).exactly(1).and_return(false)
      expect(fake_conn).not_to receive(:write)
      expect(instance).to receive(:sleep).with(0.25).and_return(nil)
      instance.subscribed['1'] = :whatever
      instance.subscribed['2'] = :whatever
      expect(instance.requests_queue.size).to eq 0
      instance.on_close(:whatever_conn)
      expect(instance.requests_queue).to eq [%({"id":"","method":"subscribeAddresses","params":{"addresses":["1","2"]}}\n)]
    end
  end

  describe 'subscribe' do
    it "validated params" do
      expect_connection
      expect { instance.subscribe(' ') }.to raise_error(ArgumentError)
    end

    it "keeps subscriptions list" do
      expect_connection
      instance.subscribe('address1') { 'callback1' }
      instance.subscribe('address2') { 'callback2' }
      expect(instance.subscribed['address1'].callback.call(['tx1'])).to eq 'callback1'
      expect(instance.subscribed['address2'].callback.call(['tx2'])).to eq 'callback2'
    end

    it "doesn't require connection" do
      expect_connection
      expect(instance.subscribe('1')).to eq false

      instance.instance_variable_set(:@connection, spy(:iodine_conn))
      expect(instance.connection).to receive(:open?).exactly(1).times.and_return(true)
      expect(instance.connection).to receive(:write).exactly(1).times

      expect(instance.subscribe('1')).to eq true # sent
    end
  end

  describe 'unsubscribe' do
    it "clears subscription list" do
      expect_connection
      instance.subscribe('1')
      instance.subscribe('2')
      instance.subscribe('3')
      expect(instance.subscribed.keys).to eq %w[1 2 3]
      expect(instance.requests_queue.last).to eq %({"id":"","method":"subscribeAddresses","params":{"addresses":["1","2","3"]}}\n)

      instance.unsubscribe('2')
      expect(instance.subscribed.keys.sort).to eq %w[1 3]
      expect(instance.requests_queue.last).to eq %({"id":"","method":"subscribeAddresses","params":{"addresses":["1","3"]}}\n)

      instance.unsubscribe(*['1', '3', 'whatever'])
      expect(instance.subscribed.keys).to be_empty
      expect(instance.requests_queue.last).to eq %({"id":"","method":"subscribeAddresses","params":{"addresses":[]}}\n)
    end
  end
end