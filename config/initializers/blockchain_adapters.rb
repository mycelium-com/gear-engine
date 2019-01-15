# frozen_string_literal: true

# Public servers: https://1209k.com/bitcoin-eye/ele.php?chain=btc
Rails.application.config.blockchain_adapters = {
  BTC:
    [
      ElectrumAPI['tcp-tls://electrumx-b.mycelium.com:4431'],
    ],
  BTC_TEST:
    [
      ElectrumAPI['tcp-tls://electrumx-b.mycelium.com:4432'],
    ],
  BCH:
    [
      ElectrumAPI['tcp-tls://bch0.kister.net:50002'],
    ],
  BCH_TEST:
    [
      ElectrumAPI['tcp-tls://bch0.kister.net:51002'],
    ],
}.with_indifferent_access
