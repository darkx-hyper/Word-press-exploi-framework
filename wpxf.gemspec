# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'wpxf'
  s.version = '2.0.0-alpha.1'
  s.date = '2018-07-14'
  s.summary = 'WordPress Exploit Framework'
  s.description = 'A Ruby framework designed to aid in the penetration testing of WordPress systems'
  s.authors = ['rastating']
  s.email = 'rob@rastating.com'
  s.files = %w[lib db data bin].map { |d| Dir["#{d}/**/*"] }.flatten + ['wpxf.gemspec']
  s.homepage = 'https://github.com/rastating/wordpress-exploit-framework'
  s.license = 'GPL-3.0'
  s.executables << 'wpxf'
  s.required_ruby_version = '>= 2.4.4'

  s.add_dependency 'colorize', '~> 0.8'
  s.add_dependency 'mime-types', '~> 3.1'
  s.add_dependency 'nokogiri', '~> 1.8'
  s.add_dependency 'require_all', '~> 2.0'
  s.add_dependency 'rubyzip', '~> 1.2'
  s.add_dependency 'sequel', '~> 5.9'
  s.add_dependency 'slop', '~> 4.6'
  s.add_dependency 'sqlite3', '~> 1.3'
  s.add_dependency 'typhoeus', '~> 1.3'

  s.add_development_dependency 'coveralls', '~> 0.8'
  s.add_development_dependency 'database_cleaner', '~> 1.7'
  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'rspec_sequel_matchers', '~> 0.5'
  s.add_development_dependency 'yard', '~> 0.9'
end
