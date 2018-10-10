class OrderParamsValidate
  include Interactor
  include InteractorLogs

  delegate :gateway, :params, to: :context

  Validation = Dry::Validation.Schema do
    required(:amount).filled(
      type?: Numeric,
      gt?:   0
    )
  end

  def call
    unless gateway.active
      context.fail!(response: {
        status: :forbidden,
        json:   { error: "This gateway is inactive" }
      })
    end
    context.order_params = normalize_params
    context.validation   = Validation.call(context.order_params)
    unless context.validation.success?
      context.fail!(response: {
        status: :unprocessable_entity,
        json:   { error: context.validation.errors }
      })
    end
  end

  def normalize_params
    raw                                = HashWithIndifferentAccess.new(context.params)
    result                             =
      {
        amount:                    raw['amount']&.to_f,
        currency:                  raw['currency'].presence,
        btc_denomination:          raw['btc_denomination'].presence,
        keychain_id:               raw['keychain_id'].presence,
        callback_data:             raw['callback_data'],
        data:                      raw['data'],
        description:               raw['description'],
        after_payment_redirect_to: raw['after_payment_redirect_to'].presence,
        auto_redirect:             raw['auto_redirect'].presence
      }
    result[:keychain_id]               ||= gateway.get_next_last_keychain_id
    result[:after_payment_redirect_to] ||= gateway.after_payment_redirect_to
    result[:auto_redirect]             ||= gateway.auto_redirect
    result[:currency]                  ||= gateway.default_currency

    result
  end
end
