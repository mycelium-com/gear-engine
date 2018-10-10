Rails.application.config.after_initialize do
  Sidekiq.configure_client do
    if ENV['ENABLE_CELLULOID'].present?
      ActorsSupervisor.boot
    end
  end
end