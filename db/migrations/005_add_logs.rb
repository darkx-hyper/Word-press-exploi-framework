# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :logs do
      primary_key :id

      column :key, :string, size: 50, unique: true, null: false
      column :value, :string, size: 100, null: false
    end
  end

  down do
    drop_table :logs
  end
end
