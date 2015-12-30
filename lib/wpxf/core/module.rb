module Wpxf
  # The base class for all modules.
  class Module
    include Wpxf::ModuleInfo
    include Wpxf::OutputEmitters
    include Wpxf::Options
    include Wpxf::WordPress::Fingerprint
    include Wpxf::WordPress::Options
    include Wpxf::WordPress::Urls

    def initialize
      super

      register_option(
        BooleanOption.new(
          name: 'verbose',
          desc: 'Enable verbose output',
          required: true,
          default: false
        )
      )

      self.event_emitter = EventEmitter.new
    end

    # @return [Boolean] true if all the required options are set.
    def can_execute?
      all_options_valid? && (!payload || payload.all_options_valid?)
    end

    # @return [Boolean] true if the target is running WordPress.
    def check_wordpress_and_online
      unless wordpress_and_online?
        emit_error "#{full_uri} does not appear to be running WordPress"
        return false
      end

      true
    end

    # Authenticate with WordPress and return the cookie.
    # @param username [String] the username to authenticate with.
    # @param password [String] the password to authenticate with.
    # @return [CookieJar, Boolean] the cookie in a CookieJar if successful,
    #   otherwise, returns false.
    def authenticate_with_wordpress(username, password)
      emit_info "Authenticating with WordPress using #{username}:#{password}..."
      cookie = wordpress_login(username, password)
      if cookie.nil?
        emit_error 'Failed to authenticate with WordPress'
        return false
      else
        emit_success 'Authenticated with WordPress', true
        return cookie
      end
    end

    # Run the module.
    # @return [Boolean] true if successful.
    def run
      true
    end

    # Check if the target is vulnerable.
    # @return [Symbol] :unknown, :vulnerable or :safe.
    def check
      :unknown
    end

    # @return [Payload] the {Payload} to use with the current module.
    attr_accessor :payload

    # @return [EventEmitter] the {EventEmitter} for the module's events.
    attr_accessor :event_emitter
  end
end
