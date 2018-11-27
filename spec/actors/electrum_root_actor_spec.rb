require 'rails_helper'

if defined? Celluloid
  RSpec.describe ElectrumRootActor do

    it "converts address to lockscripthash" do
      result = ElectrumRootActor.address_to_scripthash('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa')
      expect(result).to eq '8b01df4e368ea28f8dc0423bcf7a4923e3a12d307c875e47a0cfbf90b5c39161'
    end
  end
else
  RSpec.describe 'ElectrumRootActor' do
    xit "skipped"
  end
end