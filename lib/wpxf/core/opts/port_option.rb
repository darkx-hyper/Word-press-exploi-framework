
# frozen_string_literal: true

module Wpxf
  # A network port option.
  class PortOption < Option
    # @param value the value to normalize.
    # @return [Integer] a normalized value to conform with the type that
    #   the option is conveying.
    def normalize(value)
      value.to_i
    end

    # Check if the specified value is valid in the context of this option.
    # @param value the value to validate.
    # @return [Boolean] true if valid.
    def valid?(value)
      if value.to_s.match(/^\d+$/).nil? || (value.to_i.negative? || value.to_i > 65_535)
        return false
      end

      super
    end
  end
end
