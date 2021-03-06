# frozen_string_literal: true

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter if ENV['CI']
SimpleCov.start do
  add_filter 'db/migrations'
end

ENV['WPXF_ENV'] = 'test'

# Add the current lib to the load path to avoid testing
# against the gem, if it is installed.
base_path = File.dirname(__dir__)
$LOAD_PATH.unshift(File.join(base_path, 'lib'))

require 'wpxf'
require 'fileutils'
require 'rspec'
require 'rspec_sequel_matchers'
require 'database_cleaner'

DatabaseCleaner[:sequel].db = Sequel::Model.db

RSpec.configure do |config|
  config.include RspecSequel::Matchers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    Typhoeus::Expectation.clear
    Wpxf::Models::Workspace.insert(name: 'default')
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after(:all) do
    Dir.chdir(Dir.tmpdir) do
      temp_directories = Dir.glob('wpxf_*')
      unless temp_directories.empty?
        temp_directories.each { |d| FileUtils.rm_rf(d) }
      end
    end
  end
end
