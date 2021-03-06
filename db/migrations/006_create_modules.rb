# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :modules do
      primary_key :id

      column :path, :string, size: 255, null: false, unique: true
      column :name, :string, size: 255, null: false
      column :type, :string, size: 11, null: false
      column :class_name, :string, size: 255, null: false, unique: true
    end
  end

  down do
    drop_table :modules
  end
end
