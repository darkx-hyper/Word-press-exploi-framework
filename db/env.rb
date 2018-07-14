# frozen_string_literal: true

ENV['WPXF_ENV'] = 'development' unless ENV['WPXF_ENV']

# Use the configuration file found in ~/.wpxf/db/config.yml primarily
# and fall back onto the packaged configuration in db/config.yml.
db_config_path = File.join(Wpxf.home_directory, 'db', 'config.yml')
db_config_path = File.join(__dir__, 'config.yml') unless File.exist?(db_config_path)
db_config = YAML.load_file(db_config_path)[ENV['WPXF_ENV']]

if db_config['database'].nil?
  db_config['database'] = File.join(Wpxf.databases_path, "#{ENV['WPXF_ENV']}.db")
end

Sequel::Model.plugin :timestamps
Sequel::Model.db = Sequel.connect(db_config)

Sequel.extension :migration
Sequel::Migrator.run(Sequel::Model.db, File.join(__dir__, 'migrations'))
