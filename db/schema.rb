Sequel.migration do
  change do
    create_table(:cashila) do
      primary_key :id
      column :gateway_id, "integer", :null=>false
      column :credentials, "text"
      column :created_at, "timestamp without time zone", :null=>false
      column :updated_at, "timestamp without time zone"
      
      index [:gateway_id], :unique=>true
      index [:id], :unique=>true
    end
    
    create_table(:cashila_schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end
    
    create_table(:gatecoin) do
      primary_key :id
      column :gateway_id, "integer", :null=>false
      column :credentials, "text"
      column :created_at, "timestamp without time zone", :null=>false
      column :updated_at, "timestamp without time zone"
      
      index [:gateway_id], :unique=>true
      index [:id], :unique=>true
    end
    
    create_table(:gatecoin_schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end
    
    create_table(:gateways) do
      primary_key :id
      column :confirmations_required, "integer", :default=>0, :null=>false
      column :last_keychain_id, "integer", :default=>0, :null=>false
      column :pubkey, "text"
      column :order_class, "text", :null=>false
      column :secret, "text", :null=>false
      column :name, "text", :null=>false
      column :default_currency, "text"
      column :callback_url, "text"
      column :check_signature, "boolean", :default=>false, :null=>false
      column :exchange_rate_adapter_names, "text"
      column :created_at, "timestamp without time zone", :null=>false
      column :updated_at, "timestamp without time zone"
      column :orders_expiration_period, "integer"
      column :check_order_status_in_db_first, "boolean"
      column :active, "boolean", :default=>true
      column :order_counters, "text"
      column :hashed_id, "text"
      column :address_provider, "text", :default=>"Bip32", :null=>false
      column :address_derivation_scheme, "text"
      column :test_mode, "boolean"
      column :test_last_keychain_id, "integer", :default=>0, :null=>false
      column :test_pubkey, "text"
      column :after_payment_redirect_to, "text"
      column :auto_redirect, "boolean", :default=>false
      column :merchant_url, "text"
      column :allow_links, "boolean", :default=>false
      column :back_url, "text"
      column :custom_css_url, "text"
      column :donation_mode, "boolean", :default=>false
      column :blockchain_network, "text"
      
      index [:hashed_id]
      index [:id], :unique=>true
      index [:pubkey], :unique=>true
    end
    
    create_table(:orders) do
      primary_key :id
      column :address, "text", :null=>false
      column :tid, "text"
      column :status, "integer", :default=>0, :null=>false
      column :keychain_id, "integer", :null=>false
      column :amount, "bigint", :null=>false
      column :gateway_id, "integer", :null=>false
      column :data, "text"
      column :callback_response, "text"
      column :created_at, "timestamp without time zone", :null=>false
      column :updated_at, "timestamp without time zone"
      column :payment_id, "text"
      column :description, "text"
      column :reused, "integer", :default=>0
      column :callback_data, "text"
      column :amount_paid, "bigint"
      column :callback_url, "text"
      column :title, "text"
      column :test_mode, "boolean"
      column :after_payment_redirect_to, "text"
      column :auto_redirect, "boolean", :default=>false
      column :block_height_created_at, "integer"
      column :amount_with_currency, "text"
      
      index [:address]
      index [:id], :unique=>true
      index [:keychain_id, :gateway_id]
      index [:payment_id], :unique=>true
    end
    
    create_table(:schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end
    
    create_table(:schema_migrations) do
      column :filename, "text", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:transactions) do
      primary_key :id
      foreign_key :order_id, :orders, :key=>[:id], :on_delete=>:cascade, :on_update=>:cascade
      column :tid, "text", :null=>false
      column :amount, "bigint", :null=>false
      column :confirmations, "integer"
      column :block_height, "integer"
      column :created_at, "timestamp without time zone", :null=>false
      column :updated_at, "timestamp without time zone"
      
      index [:id], :unique=>true
      index [:order_id]
      index [:tid]
    end
  end
end
              Sequel.migration do
                change do
                  self << "SET search_path TO \"$user\", public"
                  self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20180220100705_init.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20180904084300_add_blockchain_network_to_gateways.rb')"
                end
              end
