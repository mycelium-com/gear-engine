class BlockchainTransactionsFetch
  include Interactor
  include InteractorLogs
  include BlockchainInteractor
  using SymbolCall

  delegate :address, to: :context

  def call
    context.transactions = concurrently(&:fetch_transactions_for.(address))
  end

  def blockchain_adapters
    Rails.application.config.blockchain_adapters.fetch(BlockchainNetwork[network])
  end
end
