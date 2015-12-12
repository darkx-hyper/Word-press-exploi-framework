module Wpxf
  module Net
    # Provides HTTP client functionality.
    module HttpClient
      include Wpxf::Net::UserAgent
      include Wpxf::Net::HttpOptions
      include Wpxf::Net::TyphoeusHelper

      def initialize
        super

        initialize_options
        initialize_advanced_options
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
          HTTP_OPTION_FOLLOW_REDIRECT
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
        uri = parts * '/'
        uri = uri.gsub(%r{(?<!:)//}, '/')
        unless uri.start_with?('http://') || uri.start_with?('https://')
          uri = '/' + uri
        end
        uri
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

      # Execute a HTTP request.
      # @param method the HTTP method to use (:get, :post, :put or :delete).
      # @param url the URL to request.
      # @param params a hash of the query string parameters. (optional)
      # @param body the body of the request. (optional)
      # @param headers a hash of headers to send with the request. (optional)
      # @return [Hash] a hash containing :code, :body, :headers and :timed_out
      #   keys with values set according to the response from the request.
      def execute_request(method, url, params, body, headers)
        req = create_typhoeus_request(method, url, params, body, headers)
        req.on_complete do |resp|
          return {
            code: resp.code,
            body: resp.body,
            headers: resp.headers,
            timed_out: resp.timed_out?,
            cookies: CookieJar.new.parse(resp.headers['Set-Cookie'])
          }
        end

        req.run
      end

      # Execute a HTTP GET request.
      # @param url the URL to request.
      # @param params a hash of the query string parameters. (optional)
      # @param body the body of the request. (optional)
      # @param headers a hash of headers to send with the request. (optional)
      # @return [Hash] a hash containing :code, :body, :headers and :timed_out
      #   keys with values set according to the response from the request.
      def execute_get_request(url, params = nil, body = nil, headers = {})
        execute_request(:get, url, params, body, headers)
      end

      # Execute a HTTP POST request.
      # @param url the URL to request.
      # @param params a hash of the query string parameters. (optional)
      # @param body the body of the request. (optional)
      # @param headers a hash of headers to send with the request. (optional)
      # @return [Hash] a hash containing :code, :body, :headers and :timed_out
      #   keys with values set according to the response from the request.
      def execute_post_request(url, params = nil, body = nil, headers = {})
        execute_request(:post, url, params, body, headers)
      end

      # Execute a HTTP PUT request.
      # @param url the URL to request.
      # @param params a hash of the query string parameters. (optional)
      # @param body the body of the request. (optional)
      # @param headers a hash of headers to send with the request. (optional)
      # @return [Hash] a hash containing :code, :body, :headers and :timed_out
      #   keys with values set according to the response from the request.
      def execute_put_request(url, params = nil, body = nil, headers = {})
        execute_request(:put, url, params, body, headers)
      end

      # Execute a HTTP DELETE request.
      # @param url the URL to request.
      # @param params a hash of the query string parameters. (optional)
      # @param body the body of the request. (optional)
      # @param headers a hash of headers to send with the request. (optional)
      # @return [Hash] a hash containing :code, :body, :headers and :timed_out
      #   keys with values set according to the response from the request.
      def execute_delete_request(url, params = nil, body = nil, headers = {})
        execute_request(:delete, url, params, body, headers)
      end
    end
  end
end
