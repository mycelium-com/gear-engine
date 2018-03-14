Sidekiq.configure_client do
  if ENV['ENABLE_PUBSUB_BLOCKCHAIN_ADAPTERS'].present?
    require 'pubsub_blockchain_adapters/boot'
  end
end