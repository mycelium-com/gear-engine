class BlockchainTipFetch
  include Interactor
  include InteractorLogs
  include BlockchainInteractor

  def call
    context.height = concurrently(&:latest_block_height)
  end
end
