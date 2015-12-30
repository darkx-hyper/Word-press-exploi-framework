module Wpxf
  # Provides functionality for specifying module metadata.
  module ModuleInfo
    # Initialize a new {ModuleInfo}.
    def initialize
      super
      @info = {}
    end

    # Update the module info.
    # @param info [Hash] a hash containing the module info.
    def update_info(info)
      required_keys = [:name, :desc, :author, :date]
      unless required_keys.all? { |key| info.key? key }
        fail 'Missing one or more required module info keys'
      end

      @info = info
      @info[:date] = Date.parse(@info[:date].to_s)
    end

    # @return [String] the name of the module.
    def module_name
      @info[:name]
    end

    # @return [String] the description of the module.
    def module_desc
      @info[:desc]
    end

    # @return [Array] an aray of references relating to the module.
    def module_references
      @info[:references]
    end

    # @return [Array] the name of the module author(s).
    def module_author
      @info[:author]
    end

    # @return [Date] the disclosure date of the vulnerability.
    def module_date
      @info[:date]
    end
  end
end
