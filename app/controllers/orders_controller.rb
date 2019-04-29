class OrdersController < ApiController

  before_action :find_gateway, only: %i[create]
  before_action :validate_gateway_signature, only: %i[create]
  before_action :find_order, only: %i[show cancel invoice reprocess]
  before_action :validate_order_signature, only: %i[show cancel reprocess]

  def create
    result = OrderCreate.call!(gateway: gateway, params: params.permit!.to_hash)
    render json: result.order.to_json
  end

  def show
    render json: order.to_json
  end

  def cancel
    OrderCancel.call!(order: order)
    head :ok
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

  private

  def validate_gateway_signature
    validate_signature gateway
  end

  # `gateway` is not validated to equal `order.gateway`, it's just user input extracted from URL
  def validate_order_signature
    validate_signature order.gateway
  end

  def validate_signature(gateway)
    if gateway.check_signature
      data          = signature_validator_params
      data[:secret] = gateway.secret
      StraightServer::SignatureValidator.new(**data).validate!
    end
  end

  def signature_validator_params
    {
      request_nonce:     request.headers['X-Nonce'],
      request_signature: request.headers['X-Signature'],
      request_method:    request.request_method,
      request_body:      request.body.read,
      request_uri:       request.fullpath,
    }
  end
end
