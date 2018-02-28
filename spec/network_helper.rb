require 'webmock/rspec'
VCR.configure do |config|
  config.hook_into :webmock
  config.ignore_localhost     = true
  config.cassette_library_dir = "#{__dir__}/fixtures/vcr"
end

TCR.configure do |config|
  config.hit_all = true
  config.hook_tcp_ports = [50001, 50002]
  config.cassette_library_dir = "#{__dir__}/fixtures/tcr"
end