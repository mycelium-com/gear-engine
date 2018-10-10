require 'rails_helper'

RSpec.describe ElectrumActor do

  it "subscribes to address status changes" do
    Celluloid::Actor[:ElectrumBTC].address_subscribe address: '1NDyJtNTjmwk5xPNhjgAMu4HDHigtobu1s'
  end
end