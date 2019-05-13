Sequel.migration do
  change do
    alter_table :gateways do
      add_column :removed, :boolean, default: false, null: false
    end
  end
end
