module Wpxf
  def self.underscore(module_name)
    module_name.gsub(/::/, '/').
                gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
                gsub(/([a-z\d])([A-Z])/,'\1_\2').
                tr("-", "_").
                downcase
  end

  module Auxiliary
    def self.module_list
      modules = Wpxf::Auxiliary.constants.select do |c|
        Wpxf::Auxiliary.const_get(c).is_a? Class
      end

      modules.map { |m| "auxiliary/#{Wpxf.underscore(m.to_s)}" }
    end
  end

  module Exploit
    def self.module_list
      modules = Wpxf::Exploit.constants.select do |c|
        Wpxf::Exploit.const_get(c).is_a? Class
      end

      modules.map { |m| "exploit/#{Wpxf.underscore(m.to_s)}" }
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
      payloads = Wpxf::Payloads.constants.select do |c|
        Wpxf::Payloads.const_get(c).is_a? Class
      end

      payloads.map { |p| Wpxf.underscore(p.to_s) }
    end
  end
end

require_rel 'auxiliary'
require_rel 'exploits'
require_rel '../payloads'
