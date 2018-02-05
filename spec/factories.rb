FactoryBot.define do
  factory :params, class: Hash do
    initialize_with { attributes }
  end

  factory :params_create_order, parent: :params do
    gateway_id { create(:gateway).hashed_id }
    amount 1
  end

  factory :gateway, class: StraightServer::Gateway do
    to_create &:save
    name 'A'
    pubkey 'xpub6AH1Ymkkrwk3TaMrVrXBCpcGajKc9a1dAJBTKr1i4GwYLgLk7WDvPtN1o1cAqS5DZ9CYzn3gZtT7BHEP4Qpsz24UELTncPY1Zsscsm3ajmX'
    test_pubkey 'tpubDCzMzH5R7dvZAN7jNyZRUXxuo8XdRmMd7gmzvHs9LYG4w2EBvEjQ1Drm8ZXv4uwxrtUh3MqCZQJaq56oPMghsbtFnoLi9JBfG7vRLXLH21r'
    confirmations_required 0
    order_class 'StraightServer::Order'
    secret 'secret'
    check_signature false
    default_currency 'BTC'
    orders_expiration_period 300
    exchange_rate_adapters %w[Bitpay Coinbase Bitstamp]
    active true
    test_mode true
  end

  factory :order, class: StraightServer::Order do
    to_create &:save
    initialize_with { gateway.create_order(attributes.except(:gateway)) }
    gateway
    sequence :keychain_id
    amount 1
    # FIXME: why it gets mainnet address?
  end
end
