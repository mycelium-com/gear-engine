class ElectrumRootActor
  include Celluloid
  include Celluloid::Notifications
  include CelluloidLogs

  attr_accessor :network, :address_status_changed_at
  DEBOUNCE_ADDRESS_STATUS_CHANGE = 42.seconds

  def initialize(network:)
    self.network                  = network
    self.address_status_changed_at = {}
    subscribe ElectrumActor.address_status_changed_topic(network: network), :address_status_changed
  end

  def address_subscribe(address:)
    publish ElectrumActor.address_subscribe_topic(network: network), address: address
  end

  # different servers seems to return different status strings nearly at the same time,
  # so the evidence of change is message itself, not its content
  def address_status_changed(_, address:, **)
    changed = !address_status_changed_at.has_key?(address) || (Time.now - address_status_changed_at[address]) > DEBOUNCE_ADDRESS_STATUS_CHANGE
    if changed
      address_status_changed_at[address] = Time.now
      Actor[OrderActor.id].async.status_check_stimulus address: address
      logger info: "[SignalAccepted] #{address} at #{address_status_changed_at[address]}"
    else
      logger debug: "[SignalIgnored] #{address}"
    end
  end

  def logger_tags
    "Electrum#{network}"
  end

  # https://electrumx.readthedocs.io/en/latest/protocol-basics.html#script-hashes
  def self.address_to_scripthash(address)
    script = BTC::Address.parse(address).script.to_hex
    binary = [script].pack('H*')
    hash   = Digest::SHA256.hexdigest(binary)
    hash.each_char.each_slice(2).reverse_each.to_a.join
  end
end