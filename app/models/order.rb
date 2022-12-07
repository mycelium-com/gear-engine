# Goals:
# - extract and merge business logic from Straight and StraightServer
# - accommodate new features

class Order < SimpleDelegator
  include ORM
  include GlobalID::Identification

  def self.find_by_uid(uid)
    find_by(payment_id: uid)
  end

  def self.find_by_address(address)
    find_by(address: address)
  end

  def self.each_pending(network)
    wrap_each(orm.where('"status" < 2').where(
      gateway_id: Gateway.orm.select(:id).where(
        blockchain_network: BlockchainNetwork[network].to_s)))
  end

  def self.each_final(network, addresses)
    wrap_each(orm.where('"status" >= 2').where(
      address: Array(addresses)).where(
      gateway_id: Gateway.orm.select(:id).where(
        blockchain_network: BlockchainNetwork[network].to_s)))
  end

  def gateway
    @gateway ||= Gateway.find_by_id(gateway_id) if gateway_id.present?
  end

  def to_h
    {
      status:  status,
      amount:  amount,
      address: address,
      tid:     tid, # @deprecated
      transaction_ids:      (accepted_transactions || []).map(&:tid),
      id:                   id,
      payment_id:           payment_id,
      amount_in_btc:        amount_in_btc(as: :string),
      amount_paid_in_btc:   amount_paid_in_btc,
      amount_to_pay_in_btc: amount_to_pay_in_btc,
      keychain_id:          keychain_id,
      last_keychain_id:     gateway.get_last_keychain_id
    }
  end

  def to_json
    to_h.to_json
  end
end