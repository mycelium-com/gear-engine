Sequel.migration do
  up do
    Gateway.orm.where_each(blockchain_network: nil) do |gateway|
      gateway.update(blockchain_network: gateway.test_mode ? 'BTC_TEST' : 'BTC')
    end
  end

  down do
    Rails.logger.warn "not reversed"
  end
end
