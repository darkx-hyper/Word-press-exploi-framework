module Cli
  # Methods for handling module loading and searching.
  module Modules
    def reload
      unless context
        print_bad 'No module loaded yet'
        return
      end

      begin
        mod = context.reload
        mod.event_emitter.subscribe(self)
        print_good "Reloaded module: #{mod}"
      rescue StandardError => e
        print_bad "Failed to reload module: #{e}"
      end

      # Set any globally set options.
      @global_opts.each do |k, v|
        set_option_value(k, v, true)
      end
    end

    def use(module_path)
      context = Context.new
      begin
        mod = context.load_module(module_path)
        mod.event_emitter.subscribe(self)
        print_good "Loaded module: #{mod}"
        mod.emit_usage_info
        @context_stack.push(context)
      rescue StandardError => e
        print_bad "Failed to load module: #{e}"
      end

      # Set any globally set options.
      @global_opts.each do |k, v|
        set_option_value(k, v, true)
      end

      refresh_autocomplete_options
    end

    def module_name_from_class(klass)
      klass.new.module_name
    end

    def search_modules(args)
      pattern = /#{args.map { |m| Regexp.escape(m) }.join('|')}/i
      module_list = Wpxf::Auxiliary.module_list + Wpxf::Exploit.module_list

      results = []
      module_list.select { |m| m[:name] =~ pattern }.each do |mod|
        results.push(
          path: mod[:name],
          title: module_name_from_class(mod[:class])
        )
      end

      results
    end

    def print_module_table(modules)
      modules = modules.sort_by { |k| k[:path] }
      modules.unshift(path: 'Module', title: 'Title')
      puts
      indent_cursor 2 do
        print_table(modules)
      end
    end

    def search(*args)
      results = search_modules(args)

      if !results.empty?
        print_good "#{results.length} Results for \"#{args.join(' ')}\""
        print_module_table results
      else
        print_bad "No results for \"#{args.join(' ')}\""
      end
    end
  end
end
