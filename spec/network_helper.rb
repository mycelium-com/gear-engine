require 'webmock/rspec'

VCR.configure do |config|
  config.hook_into :webmock
  config.ignore_localhost         = true
  config.cassette_library_dir     = "#{__dir__}/fixtures/vcr"
  config.default_cassette_options = { allow_unused_http_interactions: false }
end

TCR.configure do |config|
  config.hit_all              = true
  config.hook_tcp_ports       = Rails.application.config.blockchain_adapters.values.flatten.map(&:url).map(&:port)
  config.cassette_library_dir = "#{__dir__}/fixtures/tcr"
end

