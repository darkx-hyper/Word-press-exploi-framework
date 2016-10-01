require 'readline'

require 'modules'
require 'cli/auto_complete'
require 'cli/context'
require 'cli/modules'
require 'cli/module_info'
require 'cli/loaded_module'
require 'cli/options'
require 'cli/output'
require 'cli/help'

module Cli
  # Main class for running the WPXF console.
  class Console
    include Cli::AutoComplete
    include Cli::Help
    include Cli::Modules
    include Cli::LoadedModule
    include Cli::Options
    include Cli::Output

    def commands_without_output
      %w(back)
    end

    def permitted_commands
      %w(use back set show quit run unset check info gset gunset search clear
         reload)
    end

    def initialize
      @global_opts = {}
      @context_stack = []
      @indent_level = 1
      @indent = '  '

      setup_auto_complete
    end

    def context
      @context_stack.last
    end

    def back
      @context_stack.pop
      refresh_autocomplete_options
    end

    def clear
      Gem.win_platform? ? (system 'cls') : (system 'clear')
    end

    def quit
      exit
    end

    def prompt_for_input
      prompt = 'wpxf'.underline.light_blue

      # The ANSI characters cause problems with the Readline lib and
      # Windows, so if it's a Windows platform, use only plain chars.
      prompt = 'wpxf' if Gem.win_platform?

      prompt += " [#{context.module_path}]" if context
      prompt += ' > '
      Readline.readline(prompt, true)
    end

    def can_handle?(command)
      return true if respond_to?(command) && permitted_commands.include?(command)
      puts
      print_bad "\"#{command}\" is not a recognised command."
      false
    end

    def correct_number_of_args?(command, args)
      # Make an exception for set, unset and search, due to them taking
      # a variable number of strings that can contain white space.
      return true if command =~ /^(un)?set|search$/ && args.size > 1

      expected_args = Console.instance_method(command).parameters.size
      unless expected_args == args.size
        print_bad "#{args.size} arguments specified for \"#{command}\", "\
                  "expected #{expected_args}."
        return false
      end

      true
    end

    def on_event_emitted(event)
      if !event[:verbose] || context.verbose?
        if event[:type] == :table
          indent_cursor(2) do
            print_table event[:rows], true
          end
        else
          handlers = { error: 'print_bad', success: 'print_good', info: 'print_info', warning: 'print_warning' }
          send(handlers[event[:type]], event[:msg])
        end
      end
    end

    def execute_user_command(command, args)
      if can_handle? command
        puts unless commands_without_output.include? command
        send(command, *args) if correct_number_of_args?(command, args)
      end
      puts unless commands_without_output.include? command
    end

    def start
      loop do
        begin
          input = prompt_for_input
          command, *args = input.split(/\s/)
          execute_user_command(command, args) if command
        rescue StandardError => e
          print_bad "Uncaught error: #{e}"
          print_bad e.backtrace.join("\n\t")
          puts
        end
      end
    end
  end
end
