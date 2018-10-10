class OrderPersist
  include Interactor
  include InteractorLogs

  delegate :gateway, :order_params, to: :context

  def call
    Gateway.db.transaction do
      gateway.lock!
      (context.order = order_build).save
      gateway.update_last_keychain_id(context.order.keychain_id) # unless order.reused > 0
      gateway.save
    end
    Rails.logger.info "New order: #{context.order.to_h}"
  rescue Sequel::ValidationFailed => ex
    context.fail!(response: {
      status: :unprocessable_entity,
      json:   { error: ex.message }
    })
  end

  def order_build
    order             = Order.new # Kernel.const_get(gateway.order_class).new
    order.gateway     = gateway
    order.keychain_id = order_params[:keychain_id]
    order.address     = gateway.new_address(order.keychain_id)
    order.amount      = order_amount(
      **order_params.slice(:amount, :currency, :btc_denomination)
    ) do |rate|
      Rails.logger.debug "ExchangeRate: #{rate}"
      rate   = rate.reverse if rate.rate < 1
      number = ActiveSupport::NumberHelper.number_to_currency(rate.rate, precision: Currency.precision(rate.to), unit: '', delimiter: '')

      (order.data ||= {})[:exchange_rate] = {
        rate: "1 #{rate.from} = #{number} #{rate.to}",
        time: rate.time,
        src:  rate.src
      }
    end
    unless Currency[order_params[:currency]] == Currency[gateway.blockchain_currency]
      order.amount_with_currency = format("%.2f %s", order_params[:amount], order_params[:currency])
    end
    order_params.except(:currency).compact.each do |k, v|
      order.public_send "#{k}=", v
    end
    # previously: gateway.sign_with_secret("#{keychain_id}#{amount}#{created_at}#{(Order.max(:id) || 0)+1}")
    # this probably can be just UUID without any HMAC logic
    order.payment_id = gateway.sign_with_secret("#{order.address}#{order.amount}#{Time.now.to_f}")
    # TODO: maybe fetch block_height_created_at from params
    order.block_height_created_at = BlockchainTipFetch.call!(network: gateway.blockchain_network).height rescue nil

    order
  end

  # @return [Integer] amount in blockchain currency minimal unit
  def order_amount(amount:, currency:, btc_denomination: nil)
    from = Currency[currency]
    to   = Currency[gateway.blockchain_currency]
    if from == to
      if to == Currency[:BTC]
        # TODO: maybe deprecate btc_denomination param
        Satoshi.new(amount, from_unit: btc_denomination.presence || :satoshi).to_i
      else
        amount.to_i
      end
    else
      rate = ExchangeRate.convert(from: from, to: to)
      if rate.nil?
        context.fail!(response: {
          status: :unprocessable_entity,
          json:   { error: { currency: ["#{from}->#{to} exchange rate unknown"] } }
        })
      end
      yield rate if block_given?
      (rate[amount.to_d] * (10 ** Currency.precision(to))).to_i
    end
  end
end
