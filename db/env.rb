# frozen_string_literal: true

require 'sequel'
require 'yaml'

ENV['WPXF_ENV'] = 'development' unless ENV['WPXF_ENV']

db_config_path = File.join(__dir__, 'config.yml')
db_config = YAML.load_file(db_config_path)[ENV['WPXF_ENV']]

Sequel::Model.plugin :timestamps
Sequel::Model.db = Sequel.connect(db_config)
