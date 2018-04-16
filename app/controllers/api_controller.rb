class ApiController < ActionController::Base
  skip_forgery_protection

  RecordNotFound = Class.new(RuntimeError)

  rescue_from RecordNotFound do |ex|
    render status: :not_found, plain: ex.message
  end

  rescue_from StraightServer::SignatureValidator::InvalidSignature do |_ex|
    render status: :unauthorized, plain: 'X-Signature is invalid'
  end

  private

  def find_order
    order || raise(RecordNotFound, "Order not found")
  end

  def find_gateway
    gateway || raise(RecordNotFound, "Gateway not found")
  end

  # FIXME: selection by id allows to enumerate all orders on public gateway
  # it would be more private to allow only selection by payment_id
  # order.id observed to be used in:
  # - invoice link in widget QR code
  def order
    @order ||= StraightServer::Order[payment_id: params[:order_id]] || StraightServer::Order[id: params[:order_id]]
  end

  def gateway
    @gateway ||= StraightServer::Gateway[hashed_id: params[:gateway_id]]
  end
end
