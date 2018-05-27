#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'env'
require 'cli/console'

begin
  Slop.parse do |o|
    version_file_path = File.join(Wpxf.app_path, 'VERSION')

    o.on '--update', 'check for updates' do
      current_version = File.read(version_file_path).strip

      updater = Wpxf::GitHubUpdater.new
      update = updater.get_update(current_version)

      if update.nil?
        puts 'No updates available'
        exit
      end

      puts 'A new update is available!'
      puts
      puts '-- Release Notes --'
      puts update[:release_notes]
      puts
      puts "Downloading latest update (#{update[:release_name]})..."
      updater.download_and_apply_update(update[:zip_url])

      puts 'Update finished! Make sure to run "bundle install" in the WPXF directory.'
      puts
      exit
    end

    o.on '--version', 'print the version' do
      puts File.read(version_file_path).strip
      exit
    end
  end
rescue Slop::UnknownOption => e
  puts e.message
  exit
end

puts '                           _'
puts '    __      _____  _ __ __| |_ __  _ __ ___  ___ ___'
puts '    \ \ /\ / / _ \| \'__/ _` | \'_ \| \'__/ _ \/ __/ __|'
puts '     \ V  V / (_) | | | (_| | |_) | | |  __/\__ \__ \\'
puts '      \_/\_/ \___/|_|  \__,_| .__/|_|  \___||___/___/'
puts '                            |_|'
puts '                              _       _ _'
puts '               _____  ___ __ | | ___ (_) |_'
puts '              / _ \ \/ / \'_ \| |/ _ \| | __|'
puts '             |  __/>  <| |_) | | (_) | | |_'
puts '              \___/_/\_\ .__/|_|\___/|_|\__|'
puts '                       |_|'
puts '    __                                             _'
puts '   / _|_ __ __ _ _ __ ___   _____      _____  _ __| | __'
puts '  | |_| \'__/ _` | \'_ ` _ \ / _ \ \ /\ / / _ \| \'__| |/ /'
puts '  |  _| | | (_| | | | | | |  __/\ V  V / (_) | |  |   <'
puts '  |_| |_|  \__,_|_| |_| |_|\___| \_/\_/ \___/|_|  |_|\_\\'
puts

console = Cli::Console.new
puts "   Loaded #{Wpxf::Auxiliary.module_list.size} auxiliary modules, "\
     "#{Wpxf::Exploit.module_list.size} exploits, "\
     "#{Wpxf::Payloads.payload_count} payloads"
puts

Dir.chdir(Dir.tmpdir) do
  temp_directories = Dir.glob('wpxf_*')
  unless temp_directories.empty?
    print '[!] '.yellow
    puts "#{temp_directories.length} temporary files were found that "\
         'appear to no longer be needed.'
    print '    Would you like to remove these files? [y/n]: '
    temp_directories.each { |d| FileUtils.rm_r(d) } if gets.chomp =~ /^y$/i
    puts
  end
end

found_env_var = false
ENV.each do |name, value|
  next if name.casecmp('wpxf_env').zero?
  match = name.match(/^wpxf_(.+)/i)

  if match
    console.gset match.captures[0], value
    found_env_var = true
  end
end

puts if found_env_var
console.start
