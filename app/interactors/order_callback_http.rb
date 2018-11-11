require 'net/http'

class OrderCallbackHttp
  include Interactor
  include InteractorLogs

  delegate :order, :parsed_url, :request, :response, to: :context

  def call
    parse_url
    if parsed_url.nil?
      Rails.logger.debug { "#{order} [#{self.class.name}Skipped] #{order.inspect}" }
      return
    end

    Rails.logger.info { "#{order} [#{self.class.name}] #{order.inspect}" }

    context.request = Net::HTTP::Get.new(parsed_url.request_uri)
    sign_request
    http         = Net::HTTP.new(parsed_url.host, parsed_url.port)
    http.use_ssl = true if parsed_url.scheme == 'https'
    begin
      context.response = http.start do |http|
        http.request request
      end

      Rails.logger.info { "#{order} [#{self.class.name}ResponseCode] #{response.code}" }

      persist_report code: response.code, body: response.body
      handle_error :unexpected_response_code unless response.is_a?(Net::HTTPSuccess)
    rescue Timeout::Error
      handle_error :timeout
    end
  end

  def parse_url
    url = order.callback_url || order.gateway.callback_url
    return if url.blank?
    begin
      raw_uri = "#{url}#{url.include?('?') ? '&' : '?'}#{order.to_http_params}"
      uri     = URI.parse(raw_uri)
      unless uri.scheme == 'https' || uri.scheme == 'http'
        raise "unsupported protocol"
      end
      context.parsed_url = uri
    rescue => ex
      Rails.logger.info { "#{order} [#{self.class.name}AddressParsingFailed] #{raw_uri.inspect}\n#{ex.full_message}" }
      handle_error :invalid_url
    end
  end

  def sign_request
    signature = StraightServer::SignatureValidator.signature(
        method: 'GET', request_uri: parsed_url.request_uri,
        secret: order.gateway.secret, nonce: nil, body: nil)
    request.add_field 'X-Signature', signature
    Rails.logger.info { "#{order} [#{self.class.name}Details] #{parsed_url}\nSignature: #{signature}" }
  end

  def handle_error(error)
    persist_report error: error
    context.fail! error: error
  end

  def persist_report(report)
    order.callback_response =
        if order.callback_response.respond_to?(:merge)
          order.callback_response.merge(report)
        else
          report
        end
    order.save changed: true
  end
end
