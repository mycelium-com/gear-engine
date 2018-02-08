class OrderPersist
  include Interactor

  def call
    context.order = context.gateway.create_order(order_params)
  end

  def order_params
    data = context.params
    {
        amount:                    data['amount'],
        currency:                  data['currency'],
        btc_denomination:          data['btc_denomination'],
        keychain_id:               data['keychain_id'],
        callback_data:             data['callback_data'],
        data:                      data['data'],
        description:               data['description'],
        after_payment_redirect_to: data['after_payment_redirect_to'],
        auto_redirect:             data['auto_redirect']
    }
  end
end
