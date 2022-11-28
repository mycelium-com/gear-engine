source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.7'

gem 'dotenv-rails', require: 'dotenv/rails-now'
gem 'envied'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Redis adapter to run Action Cable in production
gem 'redis-rails'
# Use Iodine as the app server
gem 'iodine', '~> 0.7'
gem 'rack-cors', require: 'rack/cors'
# Background processing
gem 'sidekiq', '~> 5.2'
gem 'sidekiq-scheduler', '~> 3.0'
# gem 'thwait' # no longer bundled on ruby 2.7.0, required by sidekiq-scheduler-3.0.0/lib/sidekiq-scheduler/scheduler.rb:2
gem 'celluloid', '0.18.0', require: false
gem 'celluloid-io', require: false
# Business logic encapsulation
gem 'interactor-rails'
gem 'enumerate_it', '~> 1.7'
gem 'dry-struct', '0.6.0'
gem 'dry-validation', '0.13.1'

# indirect deps, break on update
gem 'dry-configurable', '~> 0.8.2'
gem 'dry-container', '~> 0.7.0'
gem 'dry-core', '~> 0.4.7' # just in case
gem 'redis', '~> 4.1'
gem 'redis-store', '1.6.0' # why it gets downgraded to 1.3.0?

# Straight
gem 'btcruby', github: 'EugZol/btcruby' # https://github.com/oleganza/btcruby/issues/29#issuecomment-565481659
gem 'satoshi-unit', '0.1.8' # newer version does not like floats: Satoshi::TooManyDigitsAfterDecimalPoint (Too many digits (20) after decimal point used for btc value, while 8 allowed)
# gem 'httparty', '~> 0.13.5'
# gem 'faraday'
gem 'concurrent-ruby'
# Suppress some warnings
# gem 'warning'

# Straight Server
# gem 'socket.io-client-simple'
gem 'sequel', '~> 4.25' # TODO: upgrade?
gem 'sequel-rails' #, '~> 1.0.1'
# gem 'logmaster', '~> 0.2.0'
# gem 'ruby-hmac'
gem 'ruby-protocol-buffers'
# gem 'rbtrace'

# Utils
# gem 'ice_nine', require: %w[ice_nine ice_nine/core_ext/object]

gem 'bigdecimal', '1.4.4' # https://github.com/ruby/bigdecimal#which-version-should-you-select

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails'
  # Reduces boot times through caching; required in config/boot.rb
  gem 'bootsnap', '>= 1.1.0', require: false
  gem 'rubocop-rspec'
  gem 'rb-readline'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'guard-rspec', require: false
  gem 'guard-bundler', require: false
  gem 'foreman'
end

group :test do
  gem 'rspec-retry'
  gem 'capybara', '~> 2.15'
  gem 'geckodriver-helper'
  gem 'selenium-webdriver', '~> 3.141'
  gem 'rubyzip', '~> 2.3'
  gem 'webmock'
  gem 'vcr'
  gem 'tcr'
  gem 'timecop'
  gem 'factory_bot_rails', require: false
  gem 'database_cleaner', '~> 1.7'
  gem 'json_matchers'
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
