module Wpxf
  # The base class for all payloads.
  class Payload
    # @return an encoded version of the payload.
    def encoded
      raw.to_s
    end

    # Helper method to escape single quotes in a string.
    # @param val [String] the string with quotes to escape.
    # @return [String] the string with quotes escaped.
    def escape_single_quotes(val)
      val.gsub(/'/) { "\\'" }
    end

    # Generate a random variable name.
    # @return [String] a random name beetween 1 and 9 alpha characters.
    def random_var_name
      Utility::Text.rand_alpha(rand(5..20))
    end

    # Generate a hash of variable names.
    # @param keys [Array] an array of keys.
    # @return [Hash] a hash containing a unique name for each key.
    def generate_vars(keys)
      vars = {}
      keys.each do |key|
        loop do
          var_name = random_var_name
          unless vars.value?(var_name)
            vars[key] = random_var_name
            break
          end
        end
      end
      vars
    end

    # Do any pre-exploit setup required by the payload.
    # @param mod [Module] the module using the payload.
    # @return [Boolean] true if successful.
    def prepare(mod)
      true
    end

    # Run payload specific post-exploit procedures.
    # @param mod [Module] the module using the payload.
    def post_exploit(mod)
    end

    # Cleanup any allocated resource to the payload.
    def cleanup
    end

    # Run checks to raise warnings to the user of any issues or noteworthy
    # points in regards to the payload being used with the current module.
    # @param mod [Module] the module using the payload.
    def check(mod)
    end

    # @return the payload in its raw format.
    attr_accessor :raw
  end
end
