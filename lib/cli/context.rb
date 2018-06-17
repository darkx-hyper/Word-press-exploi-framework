# frozen_string_literal: true

require 'modules'

module Cli
  # A context which modules will be used in.
  class Context
    def verbose?
      return false if self.module.nil?
      self.module.normalized_option_value('verbose')
    end

    def load_module(path)
      @module = Wpxf.load_module(path)
      @module_path = path
      @module
    end

    def reload
      load("#{@module_path}.rb")
      load_module(@module_path)
    end

    def load_payload(name)
      self.module.payload = Wpxf::Payloads.load_payload(name)
      self.module.payload.check(self.module)
      self.module.payload
    end

    attr_reader :module_path
    attr_reader :module
  end
end
