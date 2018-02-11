module ApplicationCable
  class Connection < ActionCable::Connection::Base

    identified_by :order

    def connect
      self.order = find_order
      logger.add_tags order.to_s
      subscriptions.add 'identifier' => JSON(channel: 'OrderChannel', id: order.payment_id)
    end

    def beat
      # legacy protocol keeps silent
    end

    private

    def send_welcome_message
      # not sure if it's safe to disable
    end

    def find_order
      StraightServer::Order[payment_id: request.params[:order_id]] || reject_unauthorized_connection
    end
  end
end
