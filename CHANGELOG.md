# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Production]

### Added
* `gateway.blockchain_network` attribute for using different currency like BitcoinCash
* `ORDER_CHECK_*` env vars to control polling schedule
* `BlockbookRealtimeAPI` for almost instantaneous transaction detection

### Changed
* Lots of legacy code deleted or refactored
* `ElectrumX` adapter requires protocol version `1.4` to be supported by servers

### Deprecated
* mutable `gateway.test_mode` is deprecated in favor of immutable `gateway.blockchain_network`, which can be `BTC`, `BTC_TEST`, etc.
* `gateway.exchange_rate_adapter_names` are no longer in use, exchange rates are selected automatically from all available providers

### Removed
* All blockchain adapters except [ElectrumX](https://github.com/kyuupichan/electrumx) are not supported currently
* `ENABLE_CELLULOID` env var