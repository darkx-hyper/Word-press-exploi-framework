# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'json'
require 'time'
require 'yaml'
require 'zip'

# The root namespace.
module Wpxf
  def self.gemspec
    spec_path = File.join(Wpxf.app_path, 'wpxf.gemspec')
    Gem::Specification.load(spec_path)
  end

  def self.data_directory
    File.join(app_path, 'data')
  end

  def self.app_path
    File.expand_path(File.dirname(__dir__))
  end

  def self.version
    gemspec.version.to_s
  end

  def self.home_directory
    path = File.join(Dir.home, '.wpxf')
    FileUtils.mkdir_p(path) unless File.directory?(path)
    path
  end

  def self.databases_path
    path = File.join(home_directory, 'db')
    FileUtils.mkdir_p(path) unless File.directory?(path)
    path
  end

  def self.change_stdout_sync(enabled)
    original_setting = STDOUT.sync
    STDOUT.sync = true
    yield(enabled)
    STDOUT.sync = original_setting
  end
end

Wpxf.gemspec.dependencies.each do |d|
  require d.name unless d.type == :development || d.name == 'rubyzip'
end

require_relative '../db/env'
require 'wpxf/core'
