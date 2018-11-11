Sequel.migration do
  up do
    alter_table :gateways do
      add_column :blockchain_network, :text
      set_column_default :test_mode, nil
      set_column_default :default_currency, nil
      set_column_allow_null :order_class
    end

    alter_table :orders do
      set_column_default :test_mode, nil
    end
  end

  down do
    drop_column :gateways, :blockchain_network
    Rails.logger.warn "set_column_default not reversed"
  end
end
