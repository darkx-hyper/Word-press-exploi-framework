# frozen_string_literal: true

module Wpxf
  module Helpers
    # Provides helper methods for common functionality used to export files.
    module Export
      include Wpxf::Db::Loot

      # Register the export_path option.
      # @param required [Boolean] a value indicating whether the option should be required.
      # @return [StringOption] the newly registered option.
      def register_export_path_option(required)
        opt = StringOption.new(
          name: 'export_path',
          desc: 'The path to save the file to',
          required: required
        )

        register_option(opt)
        opt
      end

      # @return [String] the path to save the file to.
      def export_path
        return nil if normalized_option_value('export_path').nil?
        File.expand_path normalized_option_value('export_path')
      end

      # @return [String] the path to a unique filename in the wpxf home directory.
      def generate_unique_filename(file_extension)
        storage_path = File.join(Dir.home, '.wpxf', 'loot')
        FileUtils.mkdir_p(storage_path) unless File.directory?(storage_path)
        filename = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}#{file_extension}"
        File.join(storage_path, filename)
      end

      # Save content to a new file and log the loot in the database.
      # @param content [String] the file content to save.
      # @param extension [String] the file extension to use when creating the file.
      # @return [Models::LootItem] the newly created {Models::LootItem}.
      def export_and_log_loot(content, description, type, extension = '')
        filename = generate_unique_filename(extension)
        File.write(filename, content)
        store_loot filename, description, type
      end
    end
  end
end
