module Cli
  # Helper methods for outputing information about the currently loaded module.
  module ModuleInfo
    def print_author
      print_std('Provided by:')
      indent_cursor do
        context.module.module_author.each do |author|
          print_std(author)
        end
      end
    end

    def print_description
      print_std('Description:')
      indent_cursor do
        print_std(wrap_text(context.module.module_desc))
      end
    end

    def print_module_summary
      print_std("       Name: #{context.module.module_name}")
      print_std("     Module: #{context.module_path}")
      print_std("  Disclosed: #{context.module.module_date}")
    end

    def print_references
      return unless context.module.module_references
      print_std('References:')
      indent_cursor do
        context.module.module_references.each do |ref|
          print_std Wpxf::Utility::ReferenceInflater.new(ref[0]).inflate(ref[1])
        end
      end
    end

    def info
      return unless module_loaded?

      print_module_summary
      puts
      print_author
      puts
      show_options
      puts
      print_description
      puts
      print_references
    end
  end
end
