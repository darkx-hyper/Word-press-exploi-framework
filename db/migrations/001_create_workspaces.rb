# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :workspaces do
      primary_key :id
      column :name, :string, size: 50, null: false
      column :created_at, :datetime
    end
  end

  down do
    drop_table :workspaces
  end
end
