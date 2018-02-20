# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development?
  begin
    StraightServer::Gateway.create(
        name:                     'A',
        pubkey:                   'xpub6AH1Ymkkrwk3TaMrVrXBCpcGajKc9a1dAJBTKr1i4GwYLgLk7WDvPtN1o1cAqS5DZ9CYzn3gZtT7BHEP4Qpsz24UELTncPY1Zsscsm3ajmX',
        test_pubkey:              'tpubDCzMzH5R7dvZAN7jNyZRUXxuo8XdRmMd7gmzvHs9LYG4w2EBvEjQ1Drm8ZXv4uwxrtUh3MqCZQJaq56oPMghsbtFnoLi9JBfG7vRLXLH21r',
        secret:                   'secret',
        order_class:              'StraightServer::Order',
        default_currency:         'BTC',
        exchange_rate_adapters:   %w[Bitpay Coinbase Bitstamp],
        confirmations_required:   0,
        orders_expiration_period: 300,
        active:                   true,
        test_mode:                true,
        check_signature:          false
    )
  rescue Sequel::UniqueConstraintViolation
    # already seeded
  ensure
    puts "Seeded:\n/gateways/#{StraightServer::Gateway.first.hashed_id}"
  end
end