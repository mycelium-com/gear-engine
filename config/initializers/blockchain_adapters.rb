# frozen_string_literal: true

# Public servers: https://1209k.com/bitcoin-eye/ele.php?chain=btc
Rails.application.config.blockchain_adapters =
  BlockchainNetwork.keys.each_with_object(HashWithIndifferentAccess.new) do |network, result|
    servers         =
      begin
        ENV["ELECTRUMX_#{network}"].split(',')
      rescue
        next
      end
    result[network] = servers.map { |url| ElectrumAPI[url] }
  end

Rails.logger.debug Rails.application.config.blockchain_adapters.inspect
