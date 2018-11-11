class ApiController < ActionController::Base
  skip_forgery_protection

  RecordNotFound = Class.new(RuntimeError)

  rescue_from RecordNotFound do |ex|
    render status: :not_found, json: { error: ex.message }
  end

  rescue_from StraightServer::SignatureValidator::InvalidSignature do |_ex|
    render status: :unauthorized, json: { error: 'X-Signature is invalid' }
  end

  rescue_from Interactor::Failure do |ex|
    response = ex.context&.response
    if response.present?
      render response
    else
      raise ex
    end
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
    @order ||= Order.find_by_uid(params[:order_id]) || Order.find_by_id(params[:order_id])
  end

  def gateway
    @gateway ||= Gateway.find_by_uid(params[:gateway_id])
  end
end
