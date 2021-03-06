# frozen_string_literal: true

require 'readline'

require 'wpxf/modules'
require 'wpxf/cli/auto_complete'
require 'wpxf/cli/creds'
require 'wpxf/cli/context'
require 'wpxf/cli/loot'
require 'wpxf/cli/modules'
require 'wpxf/cli/module_cache'
require 'wpxf/cli/module_info'
require 'wpxf/cli/loaded_module'
require 'wpxf/cli/options'
require 'wpxf/cli/output'
require 'wpxf/cli/help'
require 'wpxf/cli/workspace'

module Wpxf
  module Cli
    # Main class for running the WPXF console.
    class Console
      include Cli::AutoComplete
      include Cli::Creds
      include Cli::Help
      include Cli::Loot
      include Cli::Modules
      include Cli::ModuleCache
      include Cli::LoadedModule
      include Cli::Options
      include Cli::Output
      include Cli::Workspace

      def initialize
        super
        setup_auto_complete
      end

      def commands_without_output
        %w[back]
      end

      def permitted_commands
        %w[use back set show quit run unset check info gset setg gunset loot
           unsetg search clear reload help workspace rebuild_cache creds]
      end

      def clear
        Gem.win_platform? ? (system 'cls') : (system 'clear')
      end

      def prompt_for_input
        prompt = 'wpxf'.underline.light_blue

        # The ANSI characters cause problems with the Readline lib and
        # Windows, so if it's a Windows platform, use only plain chars.
        prompt = 'wpxf' if Gem.win_platform?
        prompt += " [#{context.module_path}]" if module_loaded?

        begin
          input = Readline.readline("#{prompt} > ", true).to_s
        rescue SignalException
          input = ''
        end

        puts if input.empty?
        input
      end

      def can_handle?(command)
        return true if respond_to?(command) && permitted_commands.include?(command)
        puts
        print_bad "\"#{command}\" is not a recognised command."
        false
      end

      def correct_number_of_args?(command, args)
        return true if command.match?(/workspace|loot|creds/)

        # Make an exception for set, unset and search, due to them taking
        # a variable number of strings that can contain white space.
        return true if command =~ /^(un)?set|search$/ && args.size > 1

        expected_args = Console.instance_method(command).parameters.size
        return true if expected_args == args.size

        print_bad "#{args.size} arguments specified for \"#{command}\", expected #{expected_args}."
        false
      end

      def on_event_emitted(event)
        return unless !event[:verbose] || context.verbose?

        if event[:type] == :table
          indent_cursor(2) { print_table event[:rows], true }
        else
          handlers = { error: 'print_bad', success: 'print_good', info: 'print_info', warning: 'print_warning' }
          send(handlers[event[:type]], event[:msg])
        end
      end

      def normalise_alised_commands(command)
        if command == 'exit'
          'quit'
        elsif command == 'setg'
          'gset'
        elsif command == 'unsetg'
          'gunset'
        else
          command
        end
      end

      def execute_user_command(command, args)
        command = normalise_alised_commands(command)
        if can_handle? command
          puts unless commands_without_output.include? command
          send(command, *args) if correct_number_of_args?(command, args)
        end
        puts unless commands_without_output.include? command
      end

      def check_cache
        return if cache_valid?
        rebuild_cache
        puts
      end

      def start
        loop do
          begin
            input = prompt_for_input
            break if input =~ /exit|quit/

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
end
