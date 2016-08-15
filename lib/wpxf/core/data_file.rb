module Wpxf
  # Represents a data file found in the data directory.
  class DataFile
    # Initialize a new instance of {DataFile}.
    # @param path_parts the path to the file, relative to the data directory.
    def initialize(*path_parts)
      self.content = File.read(File.join(Wpxf.data_directory, path_parts))
    end

    # @return [String] the contents of a PHP data file without the surrounding
    #   <?php ?> tags.
    def php_content
      content.strip.sub(/^<\?php/i, '').sub(/\?>$/i, '')
    end

    # @return [String] the contents of the data file with variable replacements.
    def content_with_named_vars(vars)
      matcher = /#{vars.keys.map { |k| Regexp.escape(k) }.join('|')}/
      content.gsub(matcher, vars)
    end

    # @return the content of the file.
    attr_accessor :content
  end
end
