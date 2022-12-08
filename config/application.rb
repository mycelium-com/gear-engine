require_relative 'boot'

# require 'rails/all'
# disabled:
# active_storage/engine
# active_record/railtie
%w(
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  rails/test_unit/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
ENVied.require(*ENV['ENVIED_GROUPS'] || Rails.groups)

module GearEngine
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.time_zone = 'UTC'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_cable.disable_request_forgery_protection = true

    config.sequel.after_connect = proc do
      Sequel.default_timezone           = :utc
      Sequel::Model.require_valid_table = false # ignore warnings after db:schema:load
      Sequel::Model.include GlobalID::Identification
      GlobalID::Locator.use :'gear-engine' do |gid|
        gid.model_class.with_pk!(gid.model_id)
      end
      Sequel::Model.db.extension :auto_literal_strings
      Sequel::Model.db.extension :connection_validator
      Sequel::Model.db.pool.connection_validation_timeout = 600
      begin
        require 'straight/lib/straight'
        require 'straight-server/lib/straight-server'
        StraightServer::Config.count_orders  = true
        StraightServer::Config.server_secret = ENV.fetch('STRAIGHT_SERVER_SECRET')
        StraightServer::Config.redis         = { prefix: "StraightServer:#{Rails.env}" }
        StraightServer.logger                = Straight.logger = Rails.logger
        StraightServer.db_connection         = Sequel::Model.db
        StraightServer.redis_connection      = Redis.current
        require 'straight-server/lib/straight-server/gateway'
        require 'straight-server/lib/straight-server/order'
        require 'straight-server/lib/straight-server/transaction'
      rescue => ex
        Sentry.capture_exception ex
        Rails.logger.error ex
      end
    end
  end
end
