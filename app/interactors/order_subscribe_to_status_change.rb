class OrderSubscribeToStatusChange
  include Interactor

  def call
    currency =
        if context.order.test_mode
          :BTC_TEST
        else
          :BTC
        end
    address  = context.order.address
    actor    = Celluloid::Actor[:"Electrum#{currency}"]
    if actor
      actor.address_subscribe address: address
    else
      Rails.logger.warn { "[OrderSubscribeToStatusChange] No actor for #{currency.inspect} currency" }
    end
  end
end
