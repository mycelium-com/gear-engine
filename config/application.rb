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

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_cable.disable_request_forgery_protection = true

    config.sequel.after_connect = proc do
      Sequel::Model.require_valid_table = false # ignore warnings after db:schema:load
      Sequel::Model.include GlobalID::Identification
      GlobalID::Locator.use :'gear-engine' do |gid|
        gid.model_class.with_pk!(gid.model_id)
      end
      require 'straight/lib/straight'
      require 'straight-server/lib/straight-server'
      begin
        StraightServer.db_connection = Sequel::Model.db
        StraightServer.db_connection.extension :connection_validator
        StraightServer.db_connection.pool.connection_validation_timeout = 600
        StraightServer.db_connection.extension :auto_literal_strings
        straight_config_dir = "#{Rails.root}/config/straight/#{Rails.env}"
        straight_config_dir = "#{Rails.root}/config/straight" unless File.exists?(straight_config_dir)
        StraightServer::Initializer::ConfigDir.set! straight_config_dir
        StraightServer::Initializer.new.prepare run_migrations: false
      rescue => ex
        Rails.logger.error ex
      end
    end
  end
end
