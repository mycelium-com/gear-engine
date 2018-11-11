module CelluloidLogs
  extend ActiveSupport::Concern

  def logger(item)
    self.class.logger(item, logger_tags)
  end

  class_methods do
    def logger(item, tags = name)
      Celluloid.logger.tagged(tags) do |logger|
        logger.public_send(*item.to_a.flatten)
      end
    end
  end
end