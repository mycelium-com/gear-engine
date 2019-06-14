class BlockchainTransactionsFetch
  include Interactor
  include InteractorLogs
  include BlockchainInteractor
  using SymbolCall

  delegate :address, to: :context

  def call
    context.transactions = concurrently(&:fetch_transactions_for.(address))
  end
end
