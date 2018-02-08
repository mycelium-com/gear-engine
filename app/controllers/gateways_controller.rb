class GatewaysController < ApiController

  before_action :find_gateway, only: %i[last_keychain_id]

  def last_keychain_id
    render json: { gateway_id: gateway.id, last_keychain_id: gateway.get_last_keychain_id }
  end
end
