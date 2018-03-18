Sidekiq.configure_client do
  file = "#{::Rails.root}/config/bip70"
  crt_file = "#{file}.crt"
  key_file = "#{file}.key"
  if [crt_file, key_file].all? { |name| File.readable?(name) }

    Rails.application.config.bip70_certs_chain =
        File.read(crt_file).each_line("-----END CERTIFICATE-----\n").map do |cert|
          OpenSSL::X509::Certificate.new(cert)
        end

    Rails.application.config.bip70_key =
        OpenSSL::PKey::RSA.new(File.read(key_file))
  else
    Rails.logger.warn "BIP70 credentials are missing"
  end
end