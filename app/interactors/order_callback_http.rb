class OrderCallbackHttp
  include Interactor

  def call
    order = context.order
    url   = order.callback_url || order.gateway.callback_url
    if url.blank?
      Rails.logger.debug { "#{order} [#{self.class.name}Skipped] #{order.inspect}" }
      return
    end
    begin
      callback_data = order.callback_data ? "&callback_data=#{CGI.escape(order.callback_data.to_s)}" : ''
      raw_uri       = "#{url}#{url.include?('?') ? '&' : '?'}#{order.to_http_params}#{callback_data}"
      uri           = URI.parse(raw_uri)
    rescue => ex
      Rails.logger.info { "#{order} [#{self.class.name}AddressParsingFailed] #{raw_uri.inspect} #{ex.inspect}" }
      context.fail! reason: :invalid_url
    end

    Rails.logger.info { "#{order} [#{self.class.name}] #{order.inspect}" }

    request   = Net::HTTP::Get.new(uri.request_uri)
    signature = StraightServer::SignatureValidator.signature(
        method: 'GET', request_uri: uri.request_uri, secret: order.gateway.secret, nonce: nil, body: nil)
    request.add_field 'X-Signature', signature

    Rails.logger.info { "#{order} [#{self.class.name}Details] #{uri}\nSignature: #{signature}" }

    http         = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    response     = context.response = http.start do |http|
      http.request request
    end

    Rails.logger.info { "#{order} [#{self.class.name}ResponseCode] #{response.code}" }

    # TODO: limit response body size
    order.callback_response = { code: response.code, body: response.body }
    order.save changed: true
    unless response.is_a?(Net::HTTPSuccess)
      context.fail! reason: :unexpected_response_code
    end
  end
end
