require 'rails_helper'

if defined? Celluloid
  RSpec.describe ElectrumRootActor do

  end
else
  RSpec.describe 'ElectrumRootActor' do
    xit "skipped"
  end
end