# frozen_string_literal: true

module Wpxf
  module Models
    # A cache of a {Wpxf::Module}'s metadata.
    class Module < Sequel::Model
      plugin :validation_helpers

      def validate
        super

        validates_presence :path
        validates_presence :name
        validates_presence :type
        validates_presence :class_name

        validates_type String, :path
        validates_type String, :name
        validates_type String, :class_name

        validates_unique :path
        validates_unique :class_name

        validates_max_length 255, :path
        validates_max_length 255, :name
        validates_max_length 255, :class_name

        validates_format /^auxiliary|exploit$/, :type
      end
    end
  end
end
