class OrdersController < ApplicationController

  def create
    # validate_signature || throttle

    begin

      order_data = {
          amount:                    params['amount'],
          currency:                  params['currency'],
          btc_denomination:          params['btc_denomination'],
          keychain_id:               params['keychain_id'],
          callback_data:             params['callback_data'],
          data:                      params['data'],
          description:               params['description'],
          after_payment_redirect_to: params['after_payment_redirect_to'],
          auto_redirect:             params['auto_redirect']
      }

      order = gateway.create_order(order_data)
      # StraightServer::Thread.new(label: order.payment_id) do
      #   # Because this is a new thread, we have to wrap the code inside in #watch_exceptions
      #   # once again. Otherwise, no watching is done. Oh, threads!
      #   StraightServer.logger.watch_exceptions do
      #     order.start_periodic_status_check
      #   end
      # end
      render json: order.to_json
    rescue Sequel::ValidationFailed => e
      StraightServer.logger.debug(
          "VALIDATION ERRORS in order, cannot create it:\n" +
              "#{e.message.split(",").each_with_index.map { |e, i| "#{i + 1}. #{e.lstrip}" }.join("\n") }\n" +
              "Order data: #{order_data.inspect}\n"
      )
      render status: 409, plain: "Invalid order: #{e.message}"
    rescue Straight::Gateway::OrderAmountInvalid => e
      render status: 409, plain: "Invalid order: #{e.message}"
    rescue StraightServer::GatewayModule::GatewayInactive
      StraightServer.logger.debug "Order creation attempt on inactive gateway #{gateway.id}"
      render status: 503, plain: "The gateway is inactive, you cannot create order with it"
    end
  end

  def show
    # validate_signature(if_unforced: false)

    if order
      # order.status(reload: true)
      # order.save if order.status_changed?
      render json: order.to_json
    end
  end

  def websocket
    ws = Faye::WebSocket.new(request.env)

    if order
      if order.status >= 2
        ws.send order.to_json
        ws.close
      else
        order.gateway.add_websocket_for_order(ws, order)
      end
    else
      ws.send('error: order not found')
      ws.close
    end

    self.response = ActionDispatch::Response.new(*ws.rack_response)
    self.response.close
  end

  def cancel
    # validate_signature(if_unforced: false)

    if order
      # order.status(reload: true)
      # order.save if order.status_changed?
      if order.cancelable?
        order.cancel
        render status: 204, plain: ' '
      else
        render status: 409, plain: "Order is not cancelable"
      end
    end
  end

  def invoice
    if order
      payment_request = Bip70::PaymentRequest.new(order: order).to_s

      # {
      #     'Expires':                   '0',
      #     'Cache-Control':             'must-revalidate, post-check=0, pre-check=0',
      # }.each do |k, v|
      #   response.headers[k] = v
      # end

      send_data payment_request, type: 'application/bitcoin-paymentrequest', filename: "i#{Time.now.to_i}.bitcoinpaymentrequest", disposition: 'inline'
    end
  end

  def reprocess
    # validate_signature || throttle

    if order
      before = order.to_json
      begin
        order.reprocess!
      rescue => ex
        render status: 409, json: %({"error":#{ex.message.inspect}})
      end
      after = order.to_json
      render json: %({"before":#{before},"after":#{after}})
    end
  end

  private

  def order
    @order ||= StraightServer::Order[payment_id: params[:order_id]]
  end

  def gateway
    @gateway ||= StraightServer::Gateway[hashed_id: params[:gateway_id]]
  end
end
