# frozen_string_literal: true

module Wpxf
  def self.build_module_list(namespace, folder_name = '')
    modules = namespace.constants.select do |c|
      namespace.const_get(c).is_a? Class
    end

    modules_directory = File.join(Wpxf.app_path, folder_name)

    modules.map do |m|
      klass = namespace.const_get(m)
      filename = klass.new.method(:initialize).source_location[0]
      {
        class: klass,
        name: filename.sub(modules_directory, '').sub(/^\//, '').sub(/\.rb$/, '')
      }
    end
  end

  def self.load_module(name)
    match = name.match(/^(auxiliary|exploit)\//i)
    raise 'Invalid module path' unless match

    type = match.captures[0]
    list = type == 'auxiliary' ? Wpxf::Auxiliary.module_list : Wpxf::Exploit.module_list

    mod = list.find { |p| p[:name] == name }
    raise "\"#{name}\" is not a valid module" if mod.nil?
    mod[:class].new
  end

  module Auxiliary
    def self.module_list
      Wpxf.build_module_list(Wpxf::Auxiliary, 'modules')
    end
  end

  module Exploit
    def self.module_list
      Wpxf.build_module_list(Wpxf::Exploit, 'modules')
    end
  end

  module Payloads
    def self.payload_count
      payloads = Wpxf::Payloads.constants.select do |c|
        Wpxf::Payloads.const_get(c).is_a? Class
      end

      payloads.size
    end

    def self.payload_list
      @@payloads ||= Wpxf.build_module_list(Wpxf::Payloads, 'payloads')
    end

    def self.load_payload(name)
      payload = payload_list.find { |p| p[:name] == name }
      raise "\"#{name}\" is not a valid payload" if payload.nil?
      payload[:class].new
    end
  end
end

require_rel 'auxiliary'
require_rel 'exploit'
require_rel '../payloads'
