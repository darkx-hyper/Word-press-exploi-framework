# frozen_string_literal: true

module Cli
  # A mixin to handle the database caching of module data.
  module ModuleCache
    def initialize
      super
      self.current_version_number = File.read(File.join(Wpxf.app_path, 'VERSION'))
    end

    def cache_valid?
      last_version_log = Models::Log.first(key: 'version')
      return false if last_version_log.nil?

      current_version = Gem::Version.new(current_version_number)
      last_version = Gem::Version.new(last_version_log.value)

      current_version == last_version
    end

    def create_module_models(type)
      namespace = type == 'exploit' ? Wpxf::Exploit : Wpxf::Auxiliary
      namespace.module_list.each do |mod|
        instance = mod[:class].new

        Models::Module.create(
          path: mod[:name],
          name: instance.module_name,
          type: type,
          class_name: mod[:class].to_s
        )
      end
    end

    def refresh_version_log
      log = Models::Log.first(key: 'version')
      log = Models::Log.new if log.nil?
      log.key = 'version'
      log.value = current_version_number
      log.save
    end

    def rebuild_cache
      print_warning 'Refreshing the module cache...'

      Models::Module.truncate

      create_module_models 'exploit'
      create_module_models 'auxiliary'

      refresh_version_log
      reset_context_stack
    end

    attr_accessor :current_version_number
  end
end
