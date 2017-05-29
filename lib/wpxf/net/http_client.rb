require 'uri'

module Wpxf
  module Net
    # Provides HTTP client functionality.
    module HttpClient
      include Wpxf::Net::UserAgent
      include Wpxf::Net::HttpOptions
      include Wpxf::Net::TyphoeusHelper

      # Initialize a new instance of {HttpClient}.
      def initialize
        super

        initialize_options
        initialize_advanced_options

        @hydra = Typhoeus::Hydra.new(max_concurrency: max_http_concurrency)
      end

      # Initialize the basic HTTP options for the module.
      def initialize_options
        register_options([
          HTTP_OPTION_HOST,
          HTTP_OPTION_PORT,
          HTTP_OPTION_SSL,
          HTTP_OPTION_VHOST,
          HTTP_OPTION_PROXY,
          HTTP_OPTION_TARGET_URI
        ])
      end

      # Initialize the advanced HTTP options for the module.
      def initialize_advanced_options
        register_advanced_options([
          HTTP_OPTION_BASIC_AUTH_CREDS,
          HTTP_OPTION_PROXY_AUTH_CREDS,
          HTTP_OPTION_HOST_VERIFICATION,
          HTTP_OPTION_MAX_CONCURRENCY,
          HTTP_OPTION_CLIENT_TIMEOUT,
          HTTP_OPTION_USER_AGENT,
          HTTP_OPTION_FOLLOW_REDIRECT,
          HTTP_OPTION_PEER_VERIFICATION
        ])

        set_option_value('user_agent', random_user_agent)
      end

      # @return [String] the base path to the WordPress application.
      def target_uri
        datastore['target_uri']
      end

      # @return [Integer] the target port number that the application is on.
      def target_port
        normalized_option_value('port')
      end

      # @return [String] the target host address.
      def target_host
        normalized_option_value('host')
      end

      # Normalize a URI to remove duplicated slashes and ensure a slash at
      # the start of the string if it doesn't start with http:// or https://.
      # @param parts the URI parts to join and normalize.
      # @return [String] a normalized URI.
      def normalize_uri(*parts)
        path = parts * '/'
        path = '/' + path unless path.start_with?('/', 'http://', 'https://')
        url = URI.parse(path)
        url.path.squeeze!('/')
        url.to_s
      end

      # Returns the base URI string.
      # @return [String] the base URI that the module targets.
      def base_uri
        uri_scheme = normalized_option_value('ssl') ? 'https' : 'http'
        uri_port = target_port == 80 ? '' : ":#{target_port}"
        "#{uri_scheme}://#{target_host}#{uri_port}"
      end

      # Returns the full URI string including the target path.
      # @return [String] the full URI that the module targets.
      def full_uri
        normalize_uri(base_uri, target_uri)
      end

      # @return [Hash] the base headers to be used in HTTP requests.
      def base_http_headers
        headers = { 'User-Agent' => datastore['user_agent'] }

        unless datastore['vhost'].nil? || datastore['vhost'].empty?
          headers['Host'] = datastore['vhost']
        end

        headers
      end

      # Queue a HTTP request to be executed later by {#execute_queued_requests}.
      # @param opts [Hash] a hash of request options.
      # @param callback [Proc] a proc to call when the request is completed.
      def queue_request(opts, &callback)
        req = create_typhoeus_request(opts)
        req.on_complete do |res|
          callback.call(Wpxf::Net::HttpResponse.new(res)) if callback
        end

        @hydra.queue req
        @hydra.queued_requests
      end

      # Execute multiple HTTP requests in parallel queued by {#queue_request}.
      def execute_queued_requests
        @hydra.run
      end

      # Execute a HTTP request.
      # @param opts [Hash] a hash of request options.
      # @return [HttpResponse, nil] a {Wpxf::Net::HttpResponse} or nil.
      def execute_request(opts)
        req = create_typhoeus_request(opts)
        req.on_complete do |res|
          return Wpxf::Net::HttpResponse.new(res)
        end

        emit_info "Requesting #{opts[:url]}...", true
        req.run
      end

      # Stream a response directly to a file (leaves the body attribute empty).
      # @param opts [Hash] a hash of request options, local_filename being the
      #   path to stream the response to.
      # @return [HttpResponse, nil] a {Wpxf::Net::HttpResponse} or nil.
      def download_file(opts)
        target_file = File.open opts[:local_filename], 'wb'
        req = create_typhoeus_request(opts)
        req.on_headers do |response|
          return Wpxf::Net::HttpResponse.new(response) if response.code != 200
        end
        req.on_body do |chunk|
          target_file.write(chunk)
        end
        req.on_complete do |response|
          target_file.close
          return Wpxf::Net::HttpResponse.new(response)
        end
        req.run
      end

      # Execute a HTTP GET request.
      # @param opts [Hash] a hash of request options.
      # @return [HttpResponse, nil] a {Wpxf::Net::HttpResponse} or nil.
      def execute_get_request(opts)
        execute_request(opts.merge(method: :get))
      end

      # Execute a HTTP POST request.
      # @param opts [Hash] a hash of request options.
      # @return [HttpResponse, nil] a {Wpxf::Net::HttpResponse} or nil.
      def execute_post_request(opts)
        execute_request(opts.merge(method: :post))
      end

      # Execute a HTTP PUT request.
      # @param opts [Hash] a hash of request options.
      # @return [HttpResponse, nil] a {Wpxf::Net::HttpResponse} or nil.
      def execute_put_request(opts)
        execute_request(opts.merge(method: :put))
      end

      # Execute a HTTP DELETE request.
      # @param opts [Hash] a hash of request options.
      # @return [HttpResponse, nil] a {Wpxf::Net::HttpResponse} or nil.
      def execute_delete_request(opts)
        execute_request(opts.merge(method: :delete))
      end

      # @return [Integer] the maximum number of threads to use when using
      #   {#execute_queued_requests}.
      def max_http_concurrency
        normalized_option_value('max_http_concurrency')
      end
    end
  end
end
