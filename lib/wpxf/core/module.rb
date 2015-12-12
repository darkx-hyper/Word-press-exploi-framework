
module Wpxf
  # The base class for all modules.
  class Module
    def initialize
      super

      self.options = []
      self.datastore = {}
    end

    # Unregister an {Option}.
    # @param opt the {Option} to unregister.
    # @return [Void] nothing.
    def unregister_option(opt)
      options.delete_if { |o| o.name.eql?(opt.name) }
    end

    # Register an {Option}.
    # @param opt the {Option} to register.
    # @return [Void] nothing.
    def register_option(opt)
      unregister_option(opt)
      options.push(opt)
      datastore[opt.name] = opt.default unless opt.default.nil?
    end

    # Register an array of {Option}.
    # @param opts the array of {Option} to register.
    # @return [Void] nothing.
    def register_options(opts)
      opts.each do |opt|
        register_option(opt)
      end
    end

    # Register an array of advanced {Option}.
    # @param opts the array of {Option} to register.
    # @return [Void] nothing.
    def register_advanced_options(opts)
      opts.each do |opt|
        opt.advanced = true
      end

      register_options(opts)
    end

    # Register an array of evasion {Option}.
    # @param opts the array of {Option} to register.
    # @return [Void] nothing.
    def register_evasion_options(opts)
      opts.each do |opt|
        opt.evasion = true
      end

      register_options(opts)
    end

    # Find and return an {Option} by its registered name.
    # @param name the name of the {Option}.
    # @return [Option, nil] the matching option or nil if not found.
    def get_option(name)
      options.find { |o| o.name.eql?(name) }
    end

    # Set the value of a module option.
    # @param name the name of the option to set.
    # @param value the value to use.
    # @return [String, Symbol] the normalized value, :invalid if the
    #   specified value is invalid or :not_found if the name is invalid.
    def set_option_value(name, value)
      opt = get_option(name)
      return :not_found unless opt

      if opt.valid?(value)
        datastore[name] = value
        return opt.normalize(value)
      else
        return :invalid
      end
    end

    # Get the value of a module option.
    # @param name the name of the option.
    # @return the option value.
    def get_option_value(name)
      datastore[name]
    end

    # Get the normalized value of a module option.
    # @param name the name of the option.
    # @return the option value.
    def normalized_option_value(name)
      option = get_option(name)
      return option.normalize(datastore[name]) unless option.nil?
    end

    # @param name the name of the option.
    # @return [Boolean] true if the specified option has a value.
    def option_value?(name)
      !datastore[name].nil? && !datastore[name].empty?
    end

    # Temporarily change the value of an option and yield a block that
    # uses the scoped value before resetting it back to the original value.
    # @param name [String] the name of the option.
    # @param value [Object] the scoped value.
    # @yieldparam value [Object] the scoped value of the option.
    # @return [Nil] nothing.
    def scoped_option_change(name, value)
      original_value = get_option_value(name)

      # Set the scoped option value and invoke the proc.
      set_option_value(name, value)
      yield(get_option_value(name))

      # Reset the option value back to the original.
      set_option_value(name, original_value)

      nil
    end

    # Run the module
    # @return [Void] nothing
    def run
    end

    # @return [Array] an array of {Option} objects used to configure
    #   the current module.
    attr_accessor :options

    # @return [Hash] a hash containing the option values specified by the user.
    attr_accessor :datastore
  end
end