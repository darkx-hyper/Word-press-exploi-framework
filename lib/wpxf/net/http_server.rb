require 'cgi'
require 'socket'

# Provides basic, single threaded HTTP server functionality.
module Wpxf::Net::HttpServer
  include Wpxf

  # Initialize a new instance of {HttpServer}.
  def initialize
    super

    register_options([
      StringOption.new(
        name: 'http_server_bind_address',
        desc: 'Address to bind the HTTP server to',
        default: '0.0.0.0',
        required: true
      ),
      PortOption.new(
        name: 'http_server_bind_port',
        desc: 'Port for the HTTP server to listen on',
        default: 80,
        required: true
      )
    ])

    @http_server_kill_switch = false
  end

  # @return [String] the address the HTTP server is bound to.
  def http_server_bind_address
    normalized_option_value('http_server_bind_address')
  end

  # @return [Integer] the port the HTTP server is listening on.
  def http_server_bind_port
    normalized_option_value('http_server_bind_port')
  end

  # Invoked when a HTTP request is made to the server.
  # @param path [String] the path requested.
  # @param params [Hash] the query string parameters.
  # @param headers [Hash] the HTTP headers.
  # @return [String] the response body to send to the client.
  def on_http_request(path, params, headers)
  end

  # @return [String] the AJAX download helper script.
  def js_ajax_download
    File.read(File.join(Wpxf.data_directory, 'js', 'ajax_download.js'))
  end

  # @return [String] the AJAX post helper script.
  def js_ajax_post
    File.read(File.join(Wpxf.data_directory, 'js', 'ajax_post.js'))
  end

  # @return [String] the JS post helper script.
  def js_post
    File.read(File.join(Wpxf.data_directory, 'js', 'post.js'))
  end

  # Start the HTTP server.
  # @param non_block [Boolean] run the server in non-blocking mode.
  def start_http_server(non_block = false)
    @tcp_server = TCPServer.new(http_server_bind_address, http_server_bind_port)
    emit_info "Started HTTP server on #{http_server_bind_address}:"\
              "#{http_server_bind_port}"

    if non_block
      @http_server_thread = Thread.new do
        http_server_loop
      end
    else
      http_server_loop
    end
  end

  # Stop the HTTP server after it has finished processing the current request.
  def stop_http_server
    emit_info 'Stopping HTTP server...', true
    @http_server_kill_switch = true
    @http_server_thread.exit if @http_server_thread
    @tcp_server.close if !@tcp_server.nil? && !@tcp_server.closed?
    emit_info 'HTTP server stopped'
  end

  # @return [Thread] thread that the server runs on when in non-blocking mode.
  def http_server_thread
    @http_server_thread
  end

  private

  def http_server_loop
    begin
      loop do
        socket = @tcp_server.accept

        begin
          response = handle_incoming_http_request(socket)
          if response
            socket.print "HTTP/1.1 200 OK\r\n"\
                         "Content-Type: text/plain\r\n"\
                         "Content-Length: #{response.bytesize}\r\n"\
                         "Connection: close\r\n"
            socket.print "\r\n"
            socket.print response
          end

          socket.close
        rescue Errno::EPIPE
          emit_warning 'A socket was closed by the requester', true
        end

        break if @http_server_kill_switch
      end
    rescue SignalException
      emit_warning 'Caught kill signal', true
    rescue StandardError => e
      emit_warning "Socket error: #{e}", true
    end

    @tcp_server.close if !@tcp_server.nil? && !@tcp_server.closed?
    @http_server_kill_switch = false
  end

  def handle_incoming_http_request(socket)
    request = socket.gets
    if request
      emit_info "Incoming HTTP request: #{request}", true

      headers = ''
      while (line = socket.gets) != "\r\n"
        headers += line
        emit_info line, true
      end

      headers = Hash[headers.each_line.map { |l| l.chomp.split(': ', 2) }]
      path = request.gsub(/^[A-Za-z]+\s(.+?)\s.*$/, '\1').chomp
      params = {}

      if path.include?('?')
        params = CGI.parse(path.split('?')[-1])
        params.each do |k, v|
          params[k] = v.join(' ')
        end
        path = path.split('?')[0]
      end

      # Dispatch parsed data to the callback in the module.
      on_http_request(path, params, headers)
    end
  end
end
