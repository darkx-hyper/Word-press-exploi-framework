# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'json'
require 'time'
require 'yaml'

required_gems = [
  'colorize',
  'mime/types',
  'nokogiri',
  'require_all',
  'sequel',
  'slop',
  'typhoeus',
  'zip'
]

required_gems.each do |gem_name|
  require gem_name
rescue LoadError
  puts
  puts "Failed to load required dependency: #{gem_name}"
  puts
  puts 'You must run "bundle install" prior to using WordPress Exploit Framework.'
  puts 'If bundler is not present on your system, you can install it by running "gem install bundler"'
  puts
  exit
end

wpxfbase = __FILE__

while File.symlink?(wpxfbase)
  wpxfbase = File.expand_path(File.readlink(wpxfbase), File.dirname(wpxfbase))
end

app_path = File.expand_path(File.join(File.dirname(wpxfbase)))

$LOAD_PATH.unshift(File.join(app_path, 'lib'))
$LOAD_PATH.unshift(File.join(app_path, 'modules'))

require_relative 'db/env'

begin
  Sequel.extension :migration
  Sequel::Migrator.check_current(Sequel::Model.db, File.join(__dir__, 'db', 'migrations'))
rescue Sequel::Migrator::NotCurrentError
  puts 'Could not load WordPress Exploit Framework: the database is out of date'.red
  print 'To update the database, run: '.yellow
  puts 'rake db:migrate'.light_white
  exit(1)
end

require 'wpxf/core'
require_relative 'github_updater'

Wpxf.app_path = app_path
Wpxf.data_directory = File.join(app_path, 'data/')
