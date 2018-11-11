module InteractorLogs
  extend ActiveSupport::Concern

  included do
    around do |interactor|
      Rails.logger.tagged(self.class.name) do
        Rails.logger.debug context.each_pair.map { |k, v| "#{k}: #{v}" }.join(', ')
        interactor.call
      end
    end
  end
end