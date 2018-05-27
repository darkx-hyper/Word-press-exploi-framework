# frozen_string_literal: true

require 'colorize'
require_relative '../db/env'

namespace :db do
  desc 'Flush all data from the database'
  task :flush do
    require_relative '../lib/models/credential'

    models = [
      ['credentials', Models::Credential]
    ]

    models.each do |model|
      print '[-] '.light_blue
      puts "Deleting #{model[0]}"
      model[1].all.each(&:destroy)
    end
  end
end
