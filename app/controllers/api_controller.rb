class ApiController < ActionController::Base
  skip_forgery_protection

  RecordNotFound = Class.new(RuntimeError)

  rescue_from RecordNotFound do |ex|
    render status: :not_found, plain: ex.message
  end

  private

  def find_order
    order || raise(RecordNotFound, "Order not found")
  end

  def find_gateway
    gateway || raise(RecordNotFound, "Gateway not found")
  end

  def order
    @order ||= StraightServer::Order[payment_id: params[:order_id]]
  end

  def gateway
    @gateway ||= StraightServer::Gateway[hashed_id: params[:gateway_id]]
  end
end
