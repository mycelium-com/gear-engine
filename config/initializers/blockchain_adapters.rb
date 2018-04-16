unless Rails.application.config.respond_to?(:blockchain_adapters_factory)
  Rails.application.config.blockchain_adapters_factory = {}
end

Rails.application.config.blockchain_adapters.each do |name, params|
  begin
    klass = Straight::Blockchain.const_get("#{name}Adapter") rescue Kernel.const_get(name)
  rescue NameError
    Rails.logger.warn "No blockchain adapter with the name #{name.inspect} was found!"
    next
  end
  params.each do |item|
    currency = item.fetch(:currency)
    url      = item.fetch(:url)
    (Rails.application.config.blockchain_adapters_factory[currency] ||= []) << -> {
      klass.new(url: url)
    }
  end
end