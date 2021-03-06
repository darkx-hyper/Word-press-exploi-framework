# frozen_string_literal: true

# Provides functionality for storing loot items.
module Wpxf::Db::Loot
  # Store a path to a new loot item in the database.
  # @param path [String] the path to the stored loot.
  # @param type [String] the type of loot acquired.
  # @return [Models::LootItem] the newly created {Models::LootItem}.
  def store_loot(path, notes = '', type = 'unknown')
    Wpxf::Models::LootItem.create(
      host: target_host,
      port: target_port,
      path: path,
      notes: notes,
      type: type,
      workspace: active_workspace
    )
  end
end
