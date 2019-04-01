# frozen_string_literal: true

# Public servers: https://1209k.com/bitcoin-eye/ele.php?chain=btc
Rails.application.config.blockchain_adapters = {
  BTC:
    [
      ElectrumAPI['tcp-tls://electrumx-c.mycelium.com:9333'],
    ],
  BTC_TEST:
    [
      ElectrumAPI['tcp-tls://testnet.qtornado.com:51002'],
    ],
  BCH:
    [
      ElectrumAPI['tcp-tls://electrumx-bch.mycelium.com:9334'],
    ],
  BCH_TEST:
    [
      ElectrumAPI['tcp-tls://electrumx-bch.mycelium.com:19334'],
    ],
}.with_indifferent_access
