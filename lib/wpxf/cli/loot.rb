# frozen_string_literal: true

module Wpxf
  module Cli
    # A mixin to provide functions to interact with loot stored in the database.
    module Loot
      def home_directory
        File.join(Dir.home, '.wpxf')
      end

      def build_loot_table
        rows = []
        rows.push(
          id: 'ID',
          host: 'Host',
          filename: 'Filename',
          notes: 'Notes',
          type: 'Type'
        )

        Wpxf::Models::LootItem.where(workspace: active_workspace).each do |item|
          rows.push(
            id: item.id,
            host: "#{item.host}:#{item.port}",
            filename: File.basename(item.path),
            notes: item.notes,
            type: item.type
          )
        end

        rows
      end

      def list_loot
        rows = build_loot_table
        print_table rows
        puts
        print_std "All filenames are relative to #{File.join(home_directory, 'loot')}".yellow
      end

      def find_loot_item(id)
        item = Wpxf::Models::LootItem.first(
          id: id.to_i,
          workspace: active_workspace
        )

        return item unless item.nil?
        print_bad "Could not find loot item #{id} in the current workspace"
      end

      def delete_loot(id)
        item = find_loot_item(id)
        return if item.nil?

        item.destroy
        print_good "Deleted item #{id}"
      end

      def print_loot_item(id)
        item = find_loot_item(id)
        return if item.nil?

        content = File.read(item.path)
        puts content
      end

      def loot(*args)
        return list_loot if args.length.zero?

        case args[0]
        when '-d'
          delete_loot(args[1])
        when '-p'
          print_loot_item(args[1])
        else
          print_warning 'Invalid option for "loot"'
        end
      end
    end
  end
end
