# frozen_string_literal: true

module Wpxf
  module Cli
    # Functionality for configuring auto-complete functionality in Readline lib.
    module AutoComplete
      def setup_auto_complete
        self.autocomplete_list = build_cmd_list
        Readline.completer_word_break_characters = ''
        Readline.completion_append_character = ' '
        Readline.completion_proc = method(:readline_completion_proc)
      end

      def readline_completion_proc(input)
        res = auto_complete_proc(input, autocomplete_list)
        return [] unless res
        res
      end

      def build_opts_hash
        opts_hash = {}
        return opts_hash unless context

        mod = context.module
        opts = mod.options.map(&:name)
        opts += mod.payload.options.map(&:name) if mod.payload
        opts.each do |o|
          opts_hash[o] = {}
        end

        opts_hash
      end

      def build_payload_names_hash
        opts_hash = {}
        return opts_hash unless context&.module&.exploit_module?

        opts_hash['payload'] = {}
        Wpxf::Payloads.payload_list.each { |p| opts_hash['payload'][p[:name]] = {} }
        opts_hash
      end

      def refresh_autocomplete_options
        opts_hash = build_opts_hash.merge(build_payload_names_hash)

        %w[set unset gset gunset setg unsetg].each do |key|
          autocomplete_list[key] = opts_hash
        end
      end

      def build_cmd_list
        cmds = {}
        permitted_commands.each { |c| cmds[c] = {} }
        Wpxf::Models::Module.each { |m| cmds['use'][m.path] = {} }
        cmds['show'] = {
          'options' => {},
          'advanced' => {},
          'exploits' => {},
          'auxiliary' => {}
        }
        cmds
      end

      # Process the current CLI input buffer to determine auto-complete options.
      # @param input [String] the current input buffer.
      # @param list [Array] the array of auto-complete options.
      # @return [Array, nil] an array of possible commands.
      def auto_complete_proc(input, list)
        res = nil

        # Nothing on this level, so return previous level.
        return res if list.keys.empty?

        # Enumerate each cmd/arg on this level, if there's a match, descend
        # into the next level and update the return value if anything is
        # returned and repeat.
        list.each do |k, v|
          next unless input =~ /^#{k}\s+/i
          res = list.keys
          trimmed_input = input.gsub(/^(#{k}\s+)(.+)/i, '\2')

          # If there wasn't another level of input, return the list from
          # the next level as the suggestions. For example, if `input` is
          # "show " (emphasis on trailing space), then return
          # ["show options", "show exploits"].
          if input.eql?(trimmed_input) && !v.keys.empty?
            res = v.keys.map { |r| input + r }
          else
            # If there was another level of input (e.g. "show o"), descend
            # into that level to find the partial matches (such as "show options").
            descended_res = auto_complete_proc(trimmed_input, v)
            if descended_res
              res = descended_res.grep(/^#{Regexp.escape(trimmed_input)}/)

              # If we have descended, we'll need to prepend the input that
              # we trimmed back into the returned results as to not overwrite
              # the previous levels in STDIN.
              res = res.map { |r| input.gsub(/^(#{k}\s+)(.+)/i, '\1') + r }
            else
              res = res.grep(/^#{Regexp.escape(input)}/)
            end

            break
          end
        end

        # If no full matches were found, check if there are partial matches
        # on the current level, and if so, return the current level as the
        # list of possible values.
        unless res
          grep_res = list.keys.grep(/^#{Regexp.escape(input)}/)
          res = grep_res if grep_res && !grep_res.empty?
        end

        res
      end

      attr_accessor :autocomplete_list
    end
  end
end
