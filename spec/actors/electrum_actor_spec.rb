require 'rails_helper'

if defined? Celluloid
  RSpec.describe ElectrumActor do

    it "subscribes to address status changes" do
      Celluloid::Actor[:ElectrumBTC].address_subscribe address: '1NDyJtNTjmwk5xPNhjgAMu4HDHigtobu1s'
    end
  end
else
  RSpec.describe 'ElectrumActor' do
    xit "skipped"
  end
end