# Gear Engine

Attempt to merge `straight` and `straight-server` gems into single Rails app.

## Hints

### Credentials decryption

See https://www.engineyard.com/blog/rails-encrypted-credentials-on-rails-5.2

Master key saved to Vault as `secret/gear-engine:RAILS_MASTER_KEY`

### Start

```bash
gem install foreman
bin/start
```

## TODO

* Order monitoring via Sidekiq
* OrdersController reprocess
* OrdersController validate_signature
* OrdersController throttle
