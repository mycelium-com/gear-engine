require 'rails_helper'

RSpec.describe GatewaysController, type: :request do

  describe "last_keychain_id action" do

    let(:gateway) { create(:gateway, test_last_keychain_id: 21, last_keychain_id: 42) }

    it "returns last keychain_id in test mode" do
      get gateway_last_keychain_id_path(gateway_id: gateway.hashed_id)
      expect(response.body).to eq %({"gateway_id":#{gateway.id},"last_keychain_id":21})
    end

    it "returns last keychain_id" do
      gateway.update test_mode: false
      get gateway_last_keychain_id_path(gateway_id: gateway.hashed_id)
      expect(response.body).to eq %({"gateway_id":#{gateway.id},"last_keychain_id":42})
    end
  end
end