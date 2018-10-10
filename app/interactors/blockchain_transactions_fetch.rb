class BlockchainTransactionsFetch
  include Interactor
  include InteractorLogs
  include BlockchainInteractor
  using SymbolCall

  delegate :address, to: :context

  def call
    result               = concurrently(&:fetch_transactions_for.(address))
    context.transactions = Straight::Transaction.from_hashes(result)
  end

  def blockchain_adapters
    Rails.application.config.blockchain_adapters.fetch(BlockchainNetwork[network])
  end
end
