module Cli
  # Methods for handling commands that interact with modules.
  module Modules
    def use(module_path)
      context = Context.new
      begin
        mod = context.load_module(module_path)
        mod.event_emitter.subscribe(self)
        print_good "Loaded module: #{mod}"
        @context_stack.push(context)
      rescue StandardError => e
        print_bad "Failed to load module: #{e}"
      end
    end

    def unset(name)
      unless context
        print_bad 'No module loaded yet'
        return
      end

      if name.eql?('payload')
        context.module.payload = nil
      else
        context.module.unset_option(name)
      end

      print_good "Unset #{name}"
    end

    def set_option_value(name, value)
      res = context.module.set_option_value(name, value)

      if res == :not_found && context.module.payload
        res = context.module.payload.set_option_value(name, value)
      end

      if res == :not_found
        print_warning "\"#{name}\" is not a valid option"
      elsif res == :invalid
        print_bad "\"#{value}\" is not a valid value"
      else
        print_good "Set #{name} => #{res}"
      end
    end

    def load_payload(name)
      if context.module.to_s.split('::')[-2].eql? 'Auxiliary'
        print_warning 'Auxiliary modules do not use payloads'
        return
      end

      begin
        payload = context.load_payload(name)
        print_good "Loaded payload: #{payload}"
      rescue StandardError => e
        print_bad "Failed to load payload: #{e}"
      end
    end

    def set(name, *args)
      value = args.join(' ')

      unless context
        print_warning 'No module loaded yet'
        return
      end

      begin
        if name.eql? 'payload'
          load_payload(value)
        else
          set_option_value(name, value)
        end
      rescue StandardError => e
        print_bad "Failed to set #{name}: #{e}"
      end
    end

    def info
      print_std("       Name: #{context.module.module_name}")
      print_std("     Module: #{context.module_path}")
      print_std("  Disclosed: #{context.module.module_date}")

      puts ''
      print_std('Provided by:')
      indent_cursor do
        context.module.module_author.each do |author|
          print_std("#{author}")
        end
      end

      puts ''
      show_options

      puts ''
      print_std('Description:')
      indent_cursor do
        print_std(wrap_text(context.module.module_desc))
      end

      if context.module.module_references
        puts ''
        print_std('References:')
        indent_cursor do
          context.module.module_references.each do |ref|
            if ref[0].eql? 'WPVDB'
              print_std("https://wpvulndb.com/vulnerabilities/#{ref[1]}")
            elsif ref[0].eql? 'OSVDB'
              print_std("http://www.osvdb.org/#{ref[1]}")
            elsif ref[0].eql? 'CVE'
              print_std("http://www.cvedetails.com/cve/#{ref[1]}")
            else
              print_std(ref[1])
            end
          end
        end
      end
    end

    def check
      if context && context.module
        state = context.module.check

        if state == :vulnerable
          print_warning 'Target appears to be vulnerable'
        elsif state == :unknown
          print_bad 'Could not determine if the target is vulnerable'
        else
          print_good 'Target appears to be safe'
        end
      else
        print_warning 'No module loaded'
      end
    end

    def run
      if context && context.module
        if context.module.can_execute?
          if context.module.run
            print_good 'Execution finished successfully'
          else
            print_bad 'Execution failed'
          end
        else
          print_bad 'One or more required options not set'
        end
      else
        print_warning 'No module loaded'
      end
    end
  end
end
