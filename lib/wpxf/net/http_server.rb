# frozen_string_literal: true

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
  # @return [String, Hash] if a string is returned, it will be used as the response body
  #  to send to the client. If a hash is returned, it should contain the keys:
  #  * +:body+ - the body text of the response.
  #  * +:type+ - the MIME type of the response.
  #  * +:headers+ - an array of header strings.
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
    return false if @is_stopping
    @is_stopping = true

    emit_info 'Stopping HTTP server...', true
    @http_server_kill_switch = true
    @http_server_thread&.exit
    @tcp_server.close if !@tcp_server.nil? && !@tcp_server.closed?
    emit_info 'HTTP server stopped'
    @is_stopping = false
  end

  # @return [Thread] thread that the server runs on when in non-blocking mode.
  def http_server_thread
    @http_server_thread
  end

  private

  def send_headers(socket, body, content_type, custom_headers)
    headers = []
    headers.push 'HTTP/1.1 200 OK'
    headers.push "Content-Type: #{content_type}"
    headers.push "Content-Length: #{body.bytesize}"
    headers += custom_headers unless custom_headers.nil?
    headers.push 'Connection: close'

    headers.each do |header|
      socket.print "#{header}\r\n"
    end
  end

  def send_response(response, socket)
    content_type = 'text/plain'
    body = ''
    custom_headers = nil

    if response.is_a? String
      body = response
    else
      body = response[:body]
      content_type = response[:type]
      custom_headers = response[:headers]
    end

    send_headers(socket, body, content_type, custom_headers)
    socket.print "\r\n"
    socket.print body
  end

  def http_server_loop
    begin
      loop do
        socket = @tcp_server.accept

        begin
          response = handle_incoming_http_request(socket)
          send_response(response, socket) if response
          socket.close
        rescue Errno::EPIPE
          emit_warning 'A socket was closed by the requester', true
        end

        break if @http_server_kill_switch
      end
    rescue SignalException
      emit_warning 'Caught kill signal', true
    rescue StandardError => e
      emit_error "Socket error: #{e}"
    end

    stop_http_server
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
