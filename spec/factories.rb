FactoryBot.define do
  factory :params, class: Hash do
    initialize_with { attributes }
  end

  factory :params_create_order, parent: :params do
    amount { 1 }

    trait :negative_amount do
      amount { -1 }
    end

    trait :no_amount do
      amount { '' }
    end

    trait :with_data do
      data { { hello: 'world' } }
    end

    trait :with_callback_data do
      callback_data { 'some random data' }
    end

    trait :USD do
      currency { 'USD' }
    end
  end

  factory :gateway, class: Gateway do
    to_create(&:save)
    name { 'A' }
    pubkey { 'xpub6AH1Ymkkrwk3TaMrVrXBCpcGajKc9a1dAJBTKr1i4GwYLgLk7WDvPtN1o1cAqS5DZ9CYzn3gZtT7BHEP4Qpsz24UELTncPY1Zsscsm3ajmX' }
    test_pubkey { 'tpubD6NzVbkrYhZ4Xd74t7wGJB1zZsJfsUL3Cf2HMaqLpJ8bHZmN2L5mHEABDyFabGayc6LG24kj1REAjrgq8Hbrf1qJQqj2AxAr4PmbXPCXzKE' }
    secret { 'secret' }
    confirmations_required { 0 }
    orders_expiration_period { 300 }
    active { true }
    check_signature { false }
    blockchain_network { 'BTC_TEST' }

    trait :with_auth do
      check_signature { true }
    end

    trait :BCH do
      blockchain_network { 'BCH_TEST' }
      # pubkey { 'tpubDCq38ccWGc2KUP8LXivti2uLyNzvDuNDggxHGVkqw9mmjruPAWkeyF8a1xxGZfwjALH5XQkxN9cemXUQ51GpPyoBd48qCbGRRMoYhUgqF74' }
    end

    trait :legacy do
      default_currency { 'BTC' }
      exchange_rate_adapter_names { %w[Bitstamp Bitpay Coinbase] }
      test_mode { true }
      order_class { 'StraightServer::Order' }
    end
  end

  factory :order, class: Order do
    to_create(&:save)
    initialize_with {
      OrderPersist.call!(
        OrderParamsValidate.call!(
          gateway: gateway, params: attributes.except(:gateway)
        )
      ).order
    }
    gateway
    sequence :keychain_id
    amount { 1 }
    # FIXME: why it gets mainnet address?

    trait :paid do
      after(:create) do |order|
        order.update status: 2, amount_paid: order.amount
      end
    end

    trait :partially_paid do
      after(:create) do |order|
        order.update status: -3, amount_paid: order.amount / 3.0
      end
    end

    trait :unconfirmed do
      after(:create) do |order|
        order.update status: 1, amount_paid: order.amount
      end
    end
  end
end
