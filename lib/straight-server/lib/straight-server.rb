require 'yaml'
require 'json'
require 'openssl'
require 'base64'
# require 'faye/websocket'
# require 'redis'
# require 'sequel'
# require 'logmaster'
# require 'straight'
# require 'socket.io-client-simple'


module StraightServer

  VERSION = File.read(File.expand_path('../', File.dirname(__FILE__)) + '/VERSION')

  class << self
    attr_accessor :db_connection, :redis_connection, :logger, :insight_client
  end

end

# require_relative 'straight-server/random_string'
require_relative 'straight-server/config'
# require_relative 'straight-server/websocket_insight_client'
# require_relative 'straight-server/thread'
require_relative 'straight-server/signature_validator'
require_relative 'straight-server/bip70/payment_request'
