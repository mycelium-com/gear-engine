class OrderActor
  include Celluloid

  def status_check_stimulus(address:)
    OrderStimulateStatusCheck.call!(address: address)
  end

  def self.id
    :OrderActor
  end
end