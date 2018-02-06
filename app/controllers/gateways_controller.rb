class GatewaysController < ApiController

  def last_keychain_id
    @gateway = StraightServer::Gateway.find_by_hashed_id(params[:gateway_id])
    render json: { gateway_id: @gateway.id, last_keychain_id: @gateway.get_last_keychain_id }
  end
end
