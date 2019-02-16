# Goals:
# - extract and merge business logic from Straight and StraightServer
# - accommodate new features

class Gateway < SimpleDelegator
  include ORM
  include GlobalID::Identification

  def self.find_by_uid(uid)
    find_by(hashed_id: uid)
  end

  def blockchain_network
    result = __getobj__.blockchain_network
    if result.nil? # old gateway
      result =
          if test_mode
            BlockchainNetwork::BTC_TEST
          else
            BlockchainNetwork::BTC
          end
    end
    result.to_s
  end

  def test_mode
    result = __getobj__.test_mode
    if result.nil? # new gateway
      network = __getobj__.blockchain_network
      raise "invalid gateway" if network.nil?
      result = network.end_with?('_TEST')
    end
    result
  end

  # same exchange rate for main and test coins
  def blockchain_currency
    blockchain_network&.gsub(/_TEST\z/, '')
  end

  # TODO: remove DB field
  def default_currency
    result = __getobj__.default_currency
    if result.nil? # new gateway
      result = blockchain_currency
    end
    result
  end

  def update_last_keychain_id(new_value = nil)
    if test_mode
      new_value ? self.test_last_keychain_id = new_value : self.test_last_keychain_id += 1
    else
      new_value ? self.last_keychain_id = new_value : self.last_keychain_id += 1
    end
  end

  def get_last_keychain_id
    test_mode ? test_last_keychain_id : last_keychain_id
  end

  def get_next_last_keychain_id
    get_last_keychain_id + 1
  end

  def new_address(keychain_id)
    path =
      if address_derivation_scheme.blank?
        # First check the depth. If the depth is 4 use '/i' notation (Mycelium iOS wallet)
        if keychain.depth > 3
          keychain_id.to_s
        else # Otherwise, use 'm/0/n' - both Electrum and Mycelium on Android
          "m/0/#{keychain_id}"
        end
      else
        address_derivation_scheme.to_s.downcase.sub('n', keychain_id.to_s)
      end
    Rails.logger.debug "Address derivation path: #{path.inspect}"
    keychain.derived_key(path).address.to_s
  end

  def keychain
    key       = test_mode ? test_pubkey : pubkey
    @keychain ||= BTC::Keychain.new(xpub: key)
  end
end