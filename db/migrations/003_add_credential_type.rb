# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table :credentials do
      add_column :type, :string, size: 20
    end
  end

  down do
    drop_column :credentials, :type
  end
end
