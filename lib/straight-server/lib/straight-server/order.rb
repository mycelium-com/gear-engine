module StraightServer
  class Order < Sequel::Model

    plugin :validation_helpers
    plugin :timestamps, create: :created_at, update: :updated_at

    plugin :serialization

    # Additional data that can be passed and stored with each order. Not returned with the callback (false, see `git show e44e3cd2`).
    serialize_attributes :marshal, :data

    # data that was provided by the merchan upon order creation and is sent back with the callback
    serialize_attributes :marshal, :callback_data

    # stores the response of the server to which the callback is issued
    serialize_attributes :marshal, :callback_response

    AmbiguityError = Class.new(RuntimeError)

    plugin :after_initialize
    def after_initialize
      @status = self[:status] || 0
    end

    def gateway
      @gateway ||= Gateway.find_by_id(gateway_id)
    end

    def gateway=(g)
      self.gateway_id = g.id
      @gateway        = g
    end

    def accepted_transactions(as: nil)
      result = Transaction.where(order_id: id).all
      case as
      when :straight
        result.map { |item| Straight::Transaction.from_hash(item.to_hash) }
      else
        result
      end
    end

    def accepted_transactions=(items)
      raise "order not persisted" unless id
      items.map do |item|
        item = item.respond_to?(:to_h) ? item.to_h : item.to_hash
        transaction = Transaction[order_id: id, tid: item[:tid]] || Transaction.new(order_id: id)
        begin
          transaction.update(item)
        rescue => ex
          StraightServer.logger.warn "Error during accepted transaction save: #{item.inspect} #{transaction.inspect} #{ex.full_message}"
        end
        transaction
      end
    end

    # @deprecated
    def tid
      (respond_to?(:[]) ? self[:tid] : @tid) || begin
        tids = (accepted_transactions || []).map { |t| t[:tid] }.join(',')
        tids.empty? ? nil : tids
      end
    end


    def self.find_by_address(address)
      where(address: address).order(Sequel.desc(:reused)).limit(1).first
    end

    def same_address_orders
      self.class.exclude(id: id).where(gateway_id: gateway_id, address: address)
    end

    def amount_in_btc(field: amount, as: :number)
      a = Satoshi.new(field, from_unit: :satoshi, to_unit: :btc)
      as == :string ? a.to_unit(as: :string) : a.to_unit
    end

    def amount_paid_in_btc
      amount_in_btc(field: amount_paid, as: :string)
    end

    def amount_to_pay
      amount.to_i - amount_paid.to_i
    end

    def amount_to_pay_in_btc
      amount_in_btc(field: amount_to_pay, as: :string)
    end

    def save(*)
      super
    rescue Sequel::PoolTimeout
      retry
    end

    def validate
      super # calling Sequel::Model validator
      # validates_unique :id # seems useless: SELECT count(*) AS "count" FROM "orders" WHERE (("id" = 1) AND ("id" != 1)) LIMIT 1
      validates_presence [:address, :keychain_id, :gateway_id, :amount]
      errors.add(:address, "already in use") if (self[:status].to_i < 2) && (same_address_orders.where('status < 2').count > 0)
    end

    def to_http_params
      # :tid param is @deprecated
      params = {
          order_id:                  id,
          amount:                    amount,
          amount_in_btc:             amount_in_btc(as: :string),
          amount_paid_in_btc:        amount_in_btc(field: amount_paid, as: :string),
          status:                    status,
          address:                   address,
          tid:                       tid,
          transaction_ids:           accepted_transactions.map(&:tid),
          keychain_id:               keychain_id,
          last_keychain_id:          gateway.last_keychain_id,
          after_payment_redirect_to: CGI.escape(after_payment_redirect_to.to_s),
          auto_redirect:             auto_redirect,
      }
      params[:callback_data] = CGI.escape(callback_data.to_s) if callback_data
      result = params.map { |k, v| "#{k}=#{v}" }.join('&')
      if data.respond_to?(:keys)
        keys = data.keys.select { |key| key.kind_of? String }
        if keys.size > 0
          result << '&'
          result << keys.map { |key| "data[#{CGI.escape(key)}]=#{CGI.escape(data[key].to_s)}" }.join('&')
        end
      end
      result
    end
  end
end
