# frozen_string_literal: true

# The root namespace.
module Wpxf
  def self.data_directory=(val)
    @@data_directory = val
  end

  def self.data_directory
    @@data_directory
  end

  def self.app_path=(val)
    @@app_path = val
  end

  def self.app_path
    @@app_path
  end

  def self.version
    File.read(File.join(Wpxf.app_path, 'VERSION')).strip
  end

  def self.change_stdout_sync(enabled)
    original_setting = STDOUT.sync
    STDOUT.sync = true
    yield(enabled)
    STDOUT.sync = original_setting
  end
end

require 'wpxf/db'
require 'wpxf/utility'

require 'wpxf/core/data_file'
require 'wpxf/core/options'
require 'wpxf/core/payload'
require 'wpxf/core/event_emitter'
require 'wpxf/core/output_emitters'
require 'wpxf/core/module_info'
require 'wpxf/core/module_authentication'

require 'wpxf/versioning'
require 'wpxf/net'
require 'wpxf/wordpress'

require 'wpxf/core/module'
