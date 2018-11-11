module StraightServer
  class SignatureValidator

    InvalidSignature = Class.new(RuntimeError)

    attr_accessor :secret, :request_signature, :request_body, :request_method, :request_uri

    def initialize(secret:, request_signature:, request_body:, request_method:, request_uri:)
      self.secret            = secret
      self.request_signature = request_signature
      self.request_body      = request_body
      self.request_method    = request_method
      self.request_uri       = request_uri
    end

    def validate!
      raise InvalidSignature unless valid_signature?
      true
    end

    def valid_signature?
      actual = request_signature.to_s.strip
      return false if actual.empty?
      actual == signature || actual == signature2 || superuser_signature?(actual)
    end

    def signature
      self.class.signature(**signature_params)
    end

    def signature2
      self.class.signature2(**signature_params)
    end

    def superuser_signature?(signature)
      return if StraightServer::Config[:superuser_public_key].to_s.empty?
      begin
        decoded = Base64.strict_decode64(signature)
      rescue
        return false
      end
      begin
        public_key = OpenSSL::PKey::RSA.new(StraightServer::Config[:superuser_public_key])
      rescue
        return
      end
      self.class.superuser_signature?(public_key: public_key, signature: decoded, **signature_params)
    rescue => ex
      StraightServer.logger.debug ex.message
      nil
    end

    def signature_params
      {
          body:        request_body,
          method:      request_method,
          request_uri: request_uri,
          secret:      secret,
      }
    end

    # Should mirror StraightServerKit.signature
    def self.signature(nonce: nil, body:, method:, request_uri:, secret:)
      sha512  = OpenSSL::Digest::SHA512.new
      request = "#{method.to_s.upcase}#{request_uri}#{sha512.digest("#{nonce}#{body}")}"
      Base64.strict_encode64 OpenSSL::HMAC.digest(sha512, secret.to_s, request)
    end

    # Some dumb libraries cannot convert into binary strings
    def self.signature2(nonce: nil, body:, method:, request_uri:, secret:)
      sha512  = OpenSSL::Digest::SHA512.new
      request = "#{method.to_s.upcase}#{request_uri}#{sha512.hexdigest("#{nonce}#{body}")}"
      OpenSSL::HMAC.hexdigest(sha512, secret.to_s, request)
    end

    def self.superuser_signature?(public_key:, signature:, nonce: nil, body:, method:, request_uri:, **)
      sha512  = OpenSSL::Digest::SHA512.new
      request = "#{method.to_s.upcase}#{request_uri}#{sha512.digest("#{nonce}#{body}")}"
      public_key.verify(sha512, signature, request)
    end
  end
end
