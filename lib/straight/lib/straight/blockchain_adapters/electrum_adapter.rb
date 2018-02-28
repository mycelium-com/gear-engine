require 'socket'
require 'openssl'
require 'json'
require 'uri'

module Straight

  module Blockchain
    # A base class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    class Electrum

      # Raised when blockchain data cannot be retrived for any reason.
      # We're not really intereste in the precise reason, although it is
      # stored in the message.
      class RequestError < StraightError;
      end

      # Raised when an invalid address is used, for example a mainnet address
      # is used on testnet and vice versa.
      class BitcoinAddressInvalid < StraightError;
      end

      # How much times try to connect to servers if ReadTimeout error appears
      MAX_TRIES = 5

      def self.support_mainnet?
        true
      end

      def self.support_testnet?
        true
      end

      def self.mainnet_adapter(url:)
        new(url)
      end

      def self.testnet_adapter(url:)
        new(url)
      end

      attr_accessor :url

      def initialize(url)
        self.url = URI(url)
      end

      def fetch_transactions_for(address)
        history = api_request('blockchain.address.get_history', address)
        cached_latest_block_height = latest_block_height
        result  = []
        (history || []).each do |item|
          raw_tx_hex = api_request('blockchain.transaction.get', item['tx_hash'])
          result << straighten_transaction(raw_tx_hex, address: address, height: item['height'], latest_block_height: cached_latest_block_height)
        rescue => ex
          Rails.logger.error "[ElectrumBlockchainAdapter] [TransactionFetchFailed] #{ex.inspect}\nAddress: #{address.inspect}\nTX: #{item.inspect}"
          next
        end
        result
      end

      def latest_block_height(**)
        api_request('blockchain.headers.subscribe')['block_height']
      end

      private def api_request(place, val = [])
        id         = ((Time.now.to_f - 1519818948) * 1000000).to_i
        tcp_socket = TCPSocket.open url.host, url.port
        if 'tcp-tls' == url.scheme
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.set_params
          socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
          socket.connect
          socket.sync_close = true
        else
          socket = tcp_socket
        end

        socket.write JSON(id: id, method: place, params: Array.wrap(val)).concat("\n")
        result = socket.gets
        parsed = JSON(result)

        if parsed['id'] != id
          Rails.logger.warn { "[ElectrumBlockchainAdapter] [UnexpectedResponse] #{[place, val].inspect}:\n#{result.inspect}" }
          raise RequestError
        elsif parsed['error']
          raise RequestError, parsed['error']
        else
          parsed['result']
        end
      ensure
        socket&.close
      end

      private def straighten_transaction(raw_tx_hex, address: nil, height: nil, latest_block_height: nil)
        transaction   = BTC::Transaction.new(hex: raw_tx_hex)
        confirmations =
            if height.to_i > 0 && latest_block_height.to_i > 0
              latest_block_height - height + 1
            else
              0
            end

        outs         = []
        total_amount = 0

        transaction.outputs.each do |out|
          amount            = out.value
          receiving_address = out.script.standard_address
          total_amount      += amount if address.nil? || receiving_address.to_s == address
          outs << { amount: amount, receiving_address: receiving_address }
        end

        {
            tid:           transaction.transaction_id,
            total_amount:  total_amount.to_i,
            confirmations: confirmations,
            block_height:  height,
            outs:          outs,
            meta:          {
                fetched_via: self,
            },
        }
      end
    end
  end
end
