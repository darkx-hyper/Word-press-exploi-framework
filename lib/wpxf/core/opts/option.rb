
module Wpxf
  # The base class for all module options.
  class Option
    # Initializes a named option.
    # @param attrs an object containing the following values
    #   * *name*: the name of the option (required)
    #   * *desc*: the description of the option (required)
    #   * *required*: whether or not the option is required
    #   * *default*: the default value of the option
    #   * *advanced*: whether or not this is an advanced option
    #   * *evasion*: whether or not this is an evasion option
    #   * *enums*: the list of potential valid values
    #   * *regex*: regex to validate the option value
    def initialize(attrs)
      if attrs[:name].nil? && attrs[:desc].nil?
        fail 'A value must be specified for :name and :desc'
      end

      self.name = attrs[:name]
      self.desc = attrs[:desc]
      update_optional_attributes(attrs)
    end

    # Update the optional attributes of the option.
    # @param attrs [Hash] the new values.
    def update_optional_attributes(attrs)
      self.required = attrs[:required] || false
      self.default = attrs[:default]
      self.advanced = attrs[:advanced] || false
      self.evasion = attrs[:evasion] || false
      self.enums = attrs[:enums]
      self.regex = attrs[:regex]
    end

    # @return [Boolean] true if this is an advanced option.
    def advanced?
      advanced
    end

    # @return [Boolean] true if this is an evasion option.
    def evasion?
      evasion
    end

    # @return [Boolean] true if this is a required option.
    def required?
      required
    end

    # Checks if the specified value is valid in the context of this option.
    # @param value the value to validate.
    # @return [Boolean] true if valid.
    def valid?(value)
      return false if empty_required_value?(value)
      return true if !required? && empty?(value)

      if regex
        if value.to_s.match(regex)
          return true
        else
          return false
        end
      end

      true
    end

    # @param value the value to check.
    # @return [Boolean] true if the value is nil or empty.
    def empty?(value)
      value.nil? || value.to_s.empty?
    end

    # @param value the value to check.
    # @return [Boolean] true if the value is not nil or empty.
    def value?(value)
      !empty?(value)
    end

    # @param value the value to check against.
    # @return [Boolean] true if the value supplied is nil or empty and
    #   it's required to be a valid value.
    def empty_required_value?(value)
      required? && empty?(value)
    end

    # @param value the value to normalize.
    # @return a normalized value to conform with the type that the option
    #   is conveying.
    def normalize(value)
      value
    end

    # @param value the value to get the display value of.
    # @return [String] a string representing a user-friendly display of
    #   the chosen value.
    def display_value(value)
      value.to_s
    end

    # @return [String] the name of the option.
    attr_accessor :name

    # @return [Boolean] whether or not the option is required.
    attr_accessor :required

    # @return [String] the description of the option.
    attr_accessor :desc

    # @return [Object, nil] the default value of the option.
    attr_accessor :default

    # @return [Boolean] whether or not this is an advanced option.
    attr_accessor :advanced

    # @return [Boolean] whether or not this is an evasion option.
    attr_accessor :evasion

    # @return [Array, nil] the list of potential valid values.
    attr_accessor :enums

    # @return [String, nil] an optional regex to validate the option value.
    attr_accessor :regex
  end
end
