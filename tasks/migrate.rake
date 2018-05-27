# frozen_string_literal: true

require 'colorize'
require_relative '../db/env'

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_t, args|
    Sequel.extension :migration
    db = Sequel::Model.db

    print '[-] '.light_blue

    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(db, 'db/migrations')
    end
  end
end
