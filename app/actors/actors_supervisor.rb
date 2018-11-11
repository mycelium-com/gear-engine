require 'celluloid/io'

class ActorsSupervisor < Celluloid::Supervision::Container
  using SymbolCall

  supervise type: OrderActor, as: OrderActor.id
  %w[
    Electrum
  ].each do |prefix|
    supported = :is_a?.("#{prefix}API".constantize)
    Rails.application.config.blockchain_adapters.each do |network, adapters|
      if adapters.any?(&supported)
        supervise type: const_get("#{prefix}RootActor"), as: :"#{prefix}#{network}", args: [network: network]
        adapters.lazy.select(&supported).each_with_index do |adapter, i|
          supervise type: const_get("#{prefix}Actor"), as: :"#{prefix}Actor#{i}", args: [network: network, url: adapter.url]
        end
      end
    end
  end

  def self.boot
    Celluloid.logger = Rails.logger
    Celluloid.boot
    Celluloid.register_shutdown
    run!
  end
end