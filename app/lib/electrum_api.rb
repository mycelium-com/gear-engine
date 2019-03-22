# frozen_string_literal: true

require 'uri'
require 'socket'
require 'openssl'
require 'json'

class ElectrumAPI

  attr_accessor :url

  def self.[](url)
    new(url: url)
  end

  # https://electrumx.readthedocs.io/en/latest/protocol-basics.html#script-hashes
  def self.address_to_scripthash(address)
    script = BTC::Address.parse(address).script.to_hex
    binary = [script].pack('H*')
    hash   = Digest::SHA256.hexdigest(binary)
    hash.each_char.each_slice(2).reverse_each.to_a.join
  end

  def initialize(url:)
    self.url = URI(url)
  end

  def fetch_transactions_for(address)
    scripthash = self.class.address_to_scripthash(address)
    result  = []
    new_session do |client|
      history = client.request(method: 'blockchain.scripthash.get_history', params: scripthash)
      history&.each do |item|
        begin
          response = client.request(method: 'blockchain.transaction.get', params: [item['tx_hash'], true]) # true means verbose
        rescue => ex
          Rails.logger.error "[ElectrumAPI] [TransactionFetchFailed] #{ex.message}\nAddress: #{address.inspect}\nTX: #{item.inspect}"
          next
        end
        begin
          raise if response['txid'] != item['tx_hash']
          tx               = Straight::Transaction.new
          tx.tid           = item['tx_hash']
          tx.block_height  = item['height']
          tx.confirmations = response['confirmations']
          tx.amount        = response['vout'].map { |out|
            if out.dig('scriptPubKey', 'addresses') == [address]
              # TODO: when/if more currencies are supported, this assumption may break
              (out['value'] * (10 ** Currency.precision(:BTC))).to_i
            else
              0
            end
          }.reduce(:+)
          result << tx
        rescue => ex
          Rails.logger.error "[ElectrumAPI] [UnexpectedResponse] #{item.inspect} =>\n#{response.inspect}\n#{ex.full_message}"
          next
        end
      end
    end
    result
  end

  def latest_block_height(**)
    new_session do |client|
      client.request(method: 'blockchain.headers.subscribe')['height']
    end
  end

  def new_session(protocol_version: '1.4')
    client = Client.new(url: url)
    client.set_protocol_version protocol_version
    yield client
  ensure
    client&.disconnect
  end


  class Client

    attr_accessor :socket, :mutex, :request_id

    def initialize(url:)
      tcp_socket      = TCPSocket.open url.host, url.port
      self.socket     =
        if url.scheme == 'tcp-tls'
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.set_params verify_mode: OpenSSL::SSL::VERIFY_NONE # TODO: configurable
          ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
          ssl_socket.connect
          ssl_socket.sync_close = true
          ssl_socket
        else
          tcp_socket
        end
      self.mutex      = Mutex.new
      self.request_id = 0
    end

    def set_protocol_version(version)
      request method: 'server.version', params: ['', version]
    end

    def request(method:, params: [])
      mutex.synchronize do
        begin
          message = JSON(jsonrpc: '2.0', method: method, params: Array.wrap(params), id: request_id).concat("\n")
          socket.write message
          parse_response(socket.gets)
        ensure
          self.request_id += 1
        end
      end
    end

    def disconnect
      return if socket.closed?
      mutex.synchronize do
        socket.close
      end
    rescue => ex
      Rails.logger.debug ex.full_message
    end

    def parse_response(response)
      parsed = JSON(response)
      if parsed['id'] != request_id
        Rails.logger.warn "[ElectrumAPI] [UnexpectedResponse] #{response.inspect}"
        raise
      elsif parsed['error']
        Rails.logger.error "[ElectrumAPI] [RequestFailed] #{parsed.inspect}"
        raise parsed['error'].inspect
      else
        parsed['result']
      end
    end
  end
end
