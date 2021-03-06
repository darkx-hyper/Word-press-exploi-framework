# frozen_string_literal: true

module Wpxf
  module Models
    # A miscellaneous log entry.
    class Log < Sequel::Model
      plugin :validation_helpers

      def validate
        super

        validates_presence :key
        validates_type String, :key
        validates_unique :key
        validates_presence :value

        validates_max_length 50, :key
        validates_max_length 100, :value
      end
    end
  end
end
