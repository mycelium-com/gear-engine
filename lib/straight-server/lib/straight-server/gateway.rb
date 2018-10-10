require 'cgi'
require 'concurrent/map'

module StraightServer
  class Gateway < Sequel::Model(:gateways)

    plugin :timestamps, create: :created_at, update: :updated_at
    plugin :serialization, :marshal, :exchange_rate_adapter_names
    plugin :after_initialize

    def self.find_by_hashed_id(s)
      self.where(hashed_id: s).first
    end

    # This virtual attribute is important because it's difficult to detect whether secret was actually
    # updated or not. Sequel's #changed_columns may mistakenly say :secret attr was changed, while it
    # hasn't. Thus we provide a manual way of ensuring this. It's also better and works as safety switch:
    # we don't want somebody accidentally updating a secret.
    attr_accessor :update_secret

    def before_create
      super
      encrypt_secret
    end

    def before_update
      encrypt_secret if @update_secret
      @update_secret = false
      super
    end

    def after_create
      update(hashed_id: OpenSSL::HMAC.digest('sha256', Config.server_secret, self.id.to_s).unpack("H*").first)
    end

    # We cannot allow to store gateway secret in a DB plaintext, this would be completetly unsecure.
    # Althougth we use symmetrical encryption here and store the encryption key in the
    # server's in a special file (~/.straight/server_secret), which in turn can also be stolen,
    # this is still marginally better than doing nothing.
    #
    # Also, server admnistrators now have the freedom of developing their own strategy
    # of storing that secret - it doesn't have to be stored on the same machine.
    def secret
      decrypt_secret
    end

    def self.find_by_id(id)
      self[id]
    end

    def sign_with_secret(content, level: 1)
      result = content.to_s
      level.times do
        result = OpenSSL::HMAC.digest('sha256', secret, result).unpack("H*").first
      end
      result
    end

    def encrypt_secret
      cipher = OpenSSL::Cipher::AES.new(128, :CBC)
      cipher.encrypt
      cipher.key = OpenSSL::HMAC.digest('sha256', 'nonce', Config.server_secret).unpack("H*").first[0, 16]

      cipher.iv = iv = OpenSSL::HMAC.digest('sha256', 'nonce', "#{self.class.max(:id)}#{Config.server_secret}").unpack("H*").first[0, 16]
      raise "cipher.iv cannot be nil" unless iv

      encrypted        = cipher.update(self[:secret]) << cipher.final()
      base64_encrypted = Base64.strict_encode64(encrypted).encode('utf-8')
      result           = "#{iv}:#{base64_encrypted}"

      # Check whether we can decrypt. It should not be possible to encrypt the
      # gateway secret unless we are sure we can decrypt it.
      if decrypt_secret(result) == self[:secret]
        self.secret = result
      else
        raise "Decrypted and original secrets don't match! Cannot proceed with writing the encrypted gateway secret."
      end
    end

    private

    def decrypt_secret(encrypted_field = self[:secret])
      decipher      = OpenSSL::Cipher::AES.new(128, :CBC)
      iv, encrypted = encrypted_field.split(':')
      decipher.decrypt
      decipher.key = OpenSSL::HMAC.digest('sha256', 'nonce', Config.server_secret).unpack("H*").first[0, 16]
      decipher.iv  = iv
      decipher.update(Base64.decode64(encrypted)) + decipher.final
    end
  end
end
