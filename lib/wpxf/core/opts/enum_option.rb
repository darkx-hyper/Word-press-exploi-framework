
module Wpxf
  # An enum option.
  class EnumOption < Option
    # Check if the specified value is valid in the context of this option.
    # @param value the value to validate.
    # @return [Boolean] true if valid.
    def valid?(value)
      return false if value && !enums.include?(value)
      super
    end
  end
end
