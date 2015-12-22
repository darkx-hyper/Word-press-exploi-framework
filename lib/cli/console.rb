require 'readline'

require 'modules'
require 'cli/context'
require 'cli/modules'
require 'cli/output'
require 'cli/help'

module Cli
  # Main class for running the WPXF console.
  class Console
    include Cli::Help
    include Cli::Modules
    include Cli::Output

    COMMANDS_WITHOUT_OUTPUT = %w(back)
    PERMITTED_COMMANDS = %w(use back set show quit)

    def initialize
      initialize_autocomplete_list

      Readline.completion_append_character = ''
      Readline.completion_proc = proc do |s|
        @autocomplete_list.grep(/^#{Regexp.escape(s)}/)
      end

      @context_stack = []
      @indent_level = 1
      @indent = '  '
    end

    def initialize_autocomplete_list
      @autocomplete_list = PERMITTED_COMMANDS
      @autocomplete_list.push('auxiliary/', 'exploit/')
      @autocomplete_list.push(*Wpxf::Auxiliary.module_list)
    end

    def context
      @context_stack.last
    end

    def back
      @context_stack.pop
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
      if respond_to?(command) && PERMITTED_COMMANDS.include?(command)
        return true
      else
        puts ''
        print_bad "\"#{command}\" is not a recognised command."
        return false
      end
    end

    def correct_number_of_args?(command, args)
      expected_args = Console.instance_method(command).parameters.size
      unless expected_args == args.size
        print_bad "#{args.size} arguments specified for \"#{command}\", "\
                  "expected #{expected_args}."
        return false
      end

      true
    end

    def run
      loop do
        input = prompt_for_input
        command, *args = input.split(/\s/)
        next unless command
        if can_handle? command
          puts '' unless COMMANDS_WITHOUT_OUTPUT.include? command
          send(command, *args) if correct_number_of_args?(command, args)
        end

        puts '' unless COMMANDS_WITHOUT_OUTPUT.include? command
      end
    end
  end
end