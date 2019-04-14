# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV']        ||= 'test'
# ENV['ENABLE_CELLULOID'] = 'yes'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'factory_bot_rails'
require 'json_matchers/rspec'
require 'capybara/rspec'
require 'rack/handler/iodine'
require 'network_helper'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|

  config.include FactoryBot::Syntax::Methods

  DatabaseCleaner.allow_remote_database_url = true
  DatabaseCleaner[:sequel].strategy         = :truncation
  DatabaseCleaner[:redis].strategy          = :truncation

  config.before :each do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
    DatabaseCleaner.clean
    allow_any_instance_of(ElectrumAPI).to receive(:latest_block_height).and_return(42)
  end

  # rspec-retry
  config.verbose_retry                = true
  config.display_try_failure_messages = true
  config.around :each, :js do |ex|
    TCR.turned_off do
      ex.run_with_retry retry: 4, retry_wait: 3
    end
  end
  # config.retry_callback = proc do |ex|
  #   if ex.metadata[:js]
  #     Capybara.reset!
  #   end
  # end

  config.before :each do |x|
    Rails.logger.debug "\n\n\nSPEC BEGIN at #{Time.now}\n#{x.metadata[:full_description]}\n"
  end

  config.after :each do |x|
    Rails.logger.debug "\nSPEC END at #{Time.now}\n#{x.metadata[:full_description]}\n\n\n"
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Capybara.register_driver :firefox_headless do |app|
  options = ::Selenium::WebDriver::Firefox::Options.new
  options.args << '--headless'

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

# From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
# Capybara::Screenshot.register_driver(:firefox_headless) do |driver, path|
#   driver.browser.save_screenshot(path)
# end

Capybara.register_server :iodine do |app, port, host|
  Iodine.workers = 1
  Iodine.threads = 1
  Iodine::Rack.run(app, Port: port, Address: host)
end

Capybara.configure do |config|
  config.server            = :iodine
  config.javascript_driver = :firefox_headless
end