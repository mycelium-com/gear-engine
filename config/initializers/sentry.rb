Sentry.init do |config|
  config.dsn                = ENV.fetch('SENTRY_DSN') { Rails.application.credentials.sentry_dsn }
  config.breadcrumbs_logger = [:active_support_logger]
  config.release            = ENV.fetch('GITHUB_SHA', nil)
  config.traces_sample_rate = 0.5
end
