Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  per_order = -> {
    get '', to: 'orders#show', as: ''
    get :invoice
    # get :websocket
    post :cancel
    post :reprocess
  }

  resources :gateways, only: [] do
    get :last_keychain_id
    resources :orders, only: %i[create], &per_order
  end

  # new shorter URLs
  resources :orders, only: [], &per_order

  resources :exchange_rates, only: %i[index]

  mount ActionCable.server => '/gateways/:gateway_id/orders/:order_id/websocket'
  mount ActionCable.server => '/orders/:order_id/websocket'

  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  # NOTE: for future API changes, date can be used as version number
  # 1. client specifies Accept-Version header with any or current date
  # 2. server uses API version that's no newer than the specified by client
end
