# frozen_string_literal: true

# Provides functionality required to gather information about users.
module Wpxf::WordPress::User
  # Checks if a user exists.
  # @param user [String] username to check.
  # @return [Boolean] true if the user exists.
  def wordpress_user_exists?(user)
    res = execute_post_request(
      url: wordpress_url_login,
      body: wordpress_login_post_body(user, Wpxf::Utility::Text.rand_alpha(6))
    )

    return true if res && res.code == 200 && (
      res.body.to_s =~ /Incorrect password/ ||
      res.body.to_s =~ /document\.getElementById\('user_pass'\)/
    )

    false
  end

  # @param cookie [String] a valid session cookie.
  # @return [Hash, nil] the profile form fields and their default values.
  def wordpress_user_profile_form_fields(cookie)
    res = execute_get_request(url: wordpress_url_admin_profile, cookie: cookie)
    return nil unless res.code == 200

    fields = {}
    res.body.scan(/<input.*?name="(.*?)".*?value="(.*?)".*?>/i) do |name, value|
      fields[name] = value
    end

    fields
  end
end
