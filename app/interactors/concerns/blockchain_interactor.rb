module BlockchainInteractor
  extend ActiveSupport::Concern

  included do
    delegate :network, to: :context
  end

  def concurrently(&block)
    Straight::BlockchainAdaptersDispatcher.new(blockchain_adapters, &block).result
  end

  def blockchain_adapters
    Rails.application.config.blockchain_adapters.fetch(BlockchainNetwork[network])
  end
end