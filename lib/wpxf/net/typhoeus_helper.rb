module Wpxf
  module Net
    # Provides helper functions for interfacing with Typhoeus in a module.
    module TyphoeusHelper
      def advanced_typhoeus_options
        {
          userpwd: datastore['BasicAuthCreds'],
          proxy: datastore['Proxy'],
          proxyuserpwd: datastore['ProxyAuthCreds'],
          ssl_verifyhost: normalized_option_value('HostVerification') ? 2 : 0,
          timeout: normalized_option_value('HTTPClientTimeout')
        }
      end

      def standard_typhoeus_options(method, params, body, headers)
        {
          method: method,
          body: body,
          params: params,
          headers: base_http_headers.merge(headers),
          followlocation: normalized_option_value('FollowHTTPRedirection')
        }
      end

      def create_typhoeus_request_options(method, params, body, headers)
        standard_typhoeus_options(method, params, body, headers)
          .merge(advanced_typhoeus_options)
      end

      def create_typhoeus_request(method, url, params, body, headers)
        options = create_typhoeus_request_options(method, params, body, headers)
        Typhoeus::Request.new(url, options)
      end
    end
  end
end
