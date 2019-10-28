# frozen_string_literal: true

require 'fileutils'

module Wpxf
  module Models
    # A loot item acquired from a target.
    class LootItem < Sequel::Model
      plugin :validation_helpers

      many_to_one :workspace

      def validate
        super

        validates_presence :host
        validates_presence :port
        validates_presence :path

        validates_numeric :port
        validates_type String, :path, allow_nil: true
        validates_type String, :type, allow_nil: false
        validates_type String, :notes, allow_nil: true

        validates_max_length 500, :path
        validates_max_length 250, :host
        validates_max_length 50, :type
        validates_max_length 100, :notes, allow_nil: true
      end

      def before_destroy
        super
        FileUtils.rm path if File.exist?(path)
      end
    end
  end
end