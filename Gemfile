source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

#ruby=ruby-2.5.0
ruby '~> 2.5.0'

gem 'dotenv-rails', require: 'dotenv/rails-now'
gem 'envied'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0.rc1'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Background processing
gem 'sidekiq'
gem 'celluloid', '0.18.0.pre', require: false
gem 'celluloid-io', require: false
# Business logic encapsulation
gem 'interactor-rails', github: 'collectiveidea/interactor-rails'

# Straight
gem 'btcruby' #, '1.1.1'
gem 'satoshi-unit', '0.1.8' # newer version does not like floats: Satoshi::TooManyDigitsAfterDecimalPoint (Too many digits (20) after decimal point used for btc value, while 8 allowed)
# gem 'httparty', '~> 0.13.5'
gem 'faraday'
gem 'concurrent-ruby'
# Suppress some warnings
gem 'warning'

# Straight Server
gem 'socket.io-client-simple'
gem 'sequel', '~> 4.25'
gem 'sequel-rails'
gem 'logmaster', '~> 0.2.0'
gem 'ruby-hmac'
gem 'ruby-protocol-buffers'
# gem 'rbtrace'


group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails'
  # Reduces boot times through caching; required in config/boot.rb
  gem 'bootsnap', '>= 1.1.0', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'guard-rspec', require: false
end

group :test do
  gem 'rspec-retry'
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  # gem 'chromedriver-helper'
  # Currently using: https://github.com/mozilla/geckodriver/releases
  gem 'webmock'
  gem 'vcr'
  gem 'tcr'
  gem 'timecop'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'json_matchers'
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
