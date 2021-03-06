Sidekiq.configure_client do
  file     = "#{::Rails.root}/config/bip70"
  crt_file = "#{file}.crt"
  key_file = "#{file}.key"
  if [crt_file, key_file].all? { |name| File.readable?(name) }
    Rails.application.config.bip70_certs_chain =
      File.read(crt_file).strip.each_line("-----END CERTIFICATE-----\n").map { |cert|
        OpenSSL::X509::Certificate.new(cert)
      }
    Rails.application.config.bip70_key =
      OpenSSL::PKey::RSA.new(File.read(key_file))
  else
    Rails.logger.warn "BIP70 credentials are missing"
  end
end