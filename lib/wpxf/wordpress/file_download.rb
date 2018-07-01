# frozen_string_literal: true

require 'fileutils'

# Provides reusable functionality for file download modules.
module Wpxf::WordPress::FileDownload
  include Wpxf

  # Initialize a new instance of {FileDownload}
  def initialize
    super
    _update_info_without_validation(
      desc: %(
        This module exploits a vulnerability which allows you to
        download any arbitrary file accessible by the user the web server is running as.
      )
    )

    register_option(
      StringOption.new(
        name: 'remote_file',
        desc: "The path to the remote file (relative to #{working_directory})",
        required: true,
        default: default_remote_file_path
      )
    )
  end

  # @return [Boolean] true if the export path option is required.
  def export_path_required
    false
  end

  # @return [String] the working directory of the vulnerable file.
  def working_directory
    nil
  end

  # @return [String] the default remote file path.
  def default_remote_file_path
    nil
  end

  # @return [String] the URL of the vulnerable file used to download remote files.
  def downloader_url
    nil
  end

  # @return [Hash] the params to be used when requesting the download file.
  def download_request_params
    nil
  end

  # @return [Hash, String] the body to be used when requesting the download file.
  def download_request_body
    nil
  end

  # @return [Symbol] the HTTP method to use when requesting the download file.
  def download_request_method
    :get
  end

  # @return [String] the path to the remote file.
  def remote_file
    normalized_option_value('remote_file')
  end

  # Validate the contents of the requested file.
  # @param content [String] the file contents.
  # @return [Boolean] true if valid.
  def validate_content(content)
    true
  end

  # A task to run before the download starts.
  # @return [Boolean] true if pre-download operations were successful.
  def before_download
    true
  end

  # @return [String] the file extension to use when downloading the file.
  def file_extension
    ''
  end

  # Run the module.
  # @return [Boolean] true if successful.
  def run
    _validate_implementation

    return false unless super
    return false unless before_download

    filename = _generate_unique_filename
    emit_info 'Downloading file...'
    res = download_file(_build_request_opts(filename))

    return false unless _validate_result(res)
    unless validate_content(res.body)
      FileUtils.rm filename, force: true
      return false
    end

    emit_success "Downloaded file to #{filename}"

    true
  end

  # @return [String] returns the path the file was downloaded to.
  attr_reader :downloaded_filename

  private

  def _generate_unique_filename
    storage_path = File.join(Dir.home, '.wpxf')
    unless File.directory?(storage_path)
      FileUtils.mkdir_p(storage_path)
    end

    filename = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}#{file_extension}"
    @downloaded_filename = File.join(storage_path, filename)
  end

  def _validate_implementation
    raise 'A value must be specified for #working_directory' unless working_directory
  end

  def _validate_result(res)
    if res.nil? || res.timed_out?
      emit_error 'Request timed out, try increasing the http_client_timeout'
      return false
    end

    return true unless res.code != 200

    emit_error "Server responded with code #{res.code}"
    false
  end

  def _build_request_opts(filename)
    {
      method: download_request_method,
      url: downloader_url,
      params: download_request_params,
      body: download_request_body,
      cookie: session_cookie,
      local_filename: filename
    }
  end
end
