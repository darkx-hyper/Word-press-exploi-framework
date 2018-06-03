# frozen_string_literal: true

ENV['WPXF_ENV'] = 'test'

require_relative '../env'
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
    Models::Workspace.insert(name: 'default')
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
