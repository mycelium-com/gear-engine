require 'uri'
require 'socket'
require 'openssl'
require 'json'

class ElectrumAPI

  attr_accessor :url

  def self.[](url)
    new(url: url)
  end

  def initialize(url:)
    self.url = URI(url)
  end

  def fetch_transactions_for(address)
    history                    = api_request('blockchain.address.get_history', address)
    cached_latest_block_height = latest_block_height
    result                     = []
    (history || []).each do |item|
      raw_tx_hex = api_request('blockchain.transaction.get', item['tx_hash'])
      result << straighten_transaction(raw_tx_hex, address: address, height: item['height'], latest_block_height: cached_latest_block_height)
    rescue => ex
      Rails.logger.error "[ElectrumBlockchainAdapter] [TransactionFetchFailed] #{ex.full_message}\nAddress: #{address.inspect}\nTX: #{item.inspect}"
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
      ssl_context.set_params verify_mode: OpenSSL::SSL::VERIFY_NONE
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
      raise
    elsif parsed['error']
      raise parsed['error'].inspect
    else
      parsed['result']
    end
  ensure
    socket&.close
  end

  private def straighten_transaction(raw_tx_hex, address: nil, height: nil, latest_block_height: nil)
    network       = address.nil? ? nil : BTC::Address.parse(address).network
    transaction   = BTC::Transaction.new(hex: raw_tx_hex)
    confirmations =
        if height.to_i > 0 && latest_block_height.to_i > 0 && latest_block_height >= height
          latest_block_height - height + 1
        else
          0
        end

    outs         = []
    total_amount = 0

    transaction.outputs.each do |out|
      amount            = out.value
      receiving_address = out.script.standard_address(network: network)
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
