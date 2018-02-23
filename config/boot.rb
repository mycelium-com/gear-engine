ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
if 'production' != ENV['RAILS_ENV'] && ENV['SPEC_COVERAGE'].nil?
  require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
end