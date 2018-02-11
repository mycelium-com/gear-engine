class OrdersController < ApiController

  before_action :find_gateway, only: %i[create]
  before_action :find_order, only: %i[show websocket cancel invoice reprocess]

  def create
    # validate_signature || throttle

    begin
      result = OrderCreate.call(gateway: gateway, params: params.permit!.to_hash)
      render json: result.order.to_json
    rescue Sequel::ValidationFailed => ex
      render status: 409, plain: "Invalid order: #{ex.message}"
    rescue Straight::Gateway::OrderAmountInvalid => ex
      render status: 409, plain: "Invalid order: #{ex.message}"
    rescue StraightServer::GatewayModule::GatewayInactive
      render status: 503, plain: "The gateway is inactive, you cannot create order with it"
    end
  end

  def show
    # validate_signature(if_unforced: false)

    # order.status(reload: true)
    # order.save if order.status_changed?
    render json: order.to_json
  end

  # def websocket
  #   ws = Faye::WebSocket.new(request.env)
  #   if order.status >= 2
  #     # FIXME: due to order.reprocess this branch may have no sense anymore
  #     ws.send order.to_json
  #     Thread.new do
  #       sleep 1
  #       ws.close
  #     end
  #   else
  #     order.gateway.add_websocket_for_order(ws, order)
  #   end
  #
  #   self.response = ActionDispatch::Response.new(*ws.rack_response)
  #   self.response.close
  # end

  def cancel
    # validate_signature(if_unforced: false)

    # order.status(reload: true)
    # order.save if order.status_changed?
    if order.cancelable?
      order.cancel
      render status: 204, plain: ' '
    else
      render status: 409, plain: "Order is not cancelable"
    end
  end

  def invoice
    payment_request = StraightServer::Bip70::PaymentRequest.new(order: order).to_s
    send_data payment_request,
              type:        'application/bitcoin-paymentrequest',
              filename:    "i#{Time.now.to_i}.bitcoinpaymentrequest",
              disposition: 'inline'
  end

  # FIXME: Probably this action should be non-blocking and only schedule reprocessing.
  # Also, with Sidekiq we may monitor lots of orders for a very long time with exponential backoff.
  # But if order suddenly gets "paid" after long time when currency rate already changed,
  # merchant will need to manually check if it has been paid enough to fulfill the order.
  # Since we aim to automate merchant's business process, we may wish to implement some
  # profitable strategy to deal with late payments.
  # Which payments are late? Probably it's transactions which were broadcasted after order has expired.
  # There may be cases when transaction was broadcasted in time, but our system just failed to detect it.
  # Maybe merchant should see full history of order updates, not just its current state.
  def reprocess
    # validate_signature || throttle
    #
    # before = order.to_json
    # begin
    #   order.reprocess!
    # rescue => ex
    #   render status: 409, json: %({"error":#{ex.message.inspect}})
    # end
    # after = order.to_json
    # render json: %({"before":#{before},"after":#{after}})

    head :not_implemented
  end
end
