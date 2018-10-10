class ExchangeRateCacheUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ExchangeRate.update_cache
  end
end
