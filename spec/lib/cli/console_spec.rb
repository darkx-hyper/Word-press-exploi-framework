# frozen_string_literal: true

require_relative '../../spec_helper'
require 'cli/console'
require 'cli/context'

describe Cli::Console do
  let(:subject) { Cli::Console.new }
  let(:win_platform?) { false }
  let(:module_loaded?) { false }
  let(:mod) { Wpxf::Module.new }
  let(:context) { Cli::Context.new }
  let(:verbose_context) { false }

  before :each, 'setup spies' do
    allow(Gem).to receive(:win_platform?).and_return(win_platform?)
    allow(Readline).to receive(:readline).and_return('input')

    allow_any_instance_of(Cli::Console).to receive(:setup_auto_complete)

    allow(subject).to receive(:system)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:rebuild_cache)
    allow(subject).to receive(:puts)
    allow(subject).to receive(:print)
    allow(subject).to receive(:execute_user_command).and_call_original
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_table)
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:print_info)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:indent_cursor).and_call_original
    allow(subject).to receive(:module_loaded?).and_return(module_loaded?)
    allow(subject).to receive(:context).and_return(context)
    allow(subject).to receive(:normalise_alised_commands).and_call_original

    allow(subject.context).to receive(:module).and_return(mod)
    allow(subject.context).to receive(:verbose?).and_return(verbose_context)
  end

  describe '#new' do
    it 'should setup the auto complete options' do
      expect(subject).to have_received(:setup_auto_complete).exactly(1).times
    end
  end

  describe '#commands_without_output' do
    it 'should include `back`' do
      expect(subject.commands_without_output).to include('back')
    end
  end

  describe '#permitted_commands' do
    it 'should include `use`' do
      expect(subject.permitted_commands).to include('use')
    end

    it 'should include `back`' do
      expect(subject.permitted_commands).to include('back')
    end

    it 'should include `set`' do
      expect(subject.permitted_commands).to include('set')
    end

    it 'should include `show`' do
      expect(subject.permitted_commands).to include('show')
    end

    it 'should include `quit`' do
      expect(subject.permitted_commands).to include('quit')
    end

    it 'should include `run`' do
      expect(subject.permitted_commands).to include('run')
    end

    it 'should include `unset`' do
      expect(subject.permitted_commands).to include('unset')
    end

    it 'should include `check`' do
      expect(subject.permitted_commands).to include('check')
    end

    it 'should include `info`' do
      expect(subject.permitted_commands).to include('info')
    end

    it 'should include `gset`' do
      expect(subject.permitted_commands).to include('gset')
    end

    it 'should include `setg`' do
      expect(subject.permitted_commands).to include('setg')
    end

    it 'should include `gunset`' do
      expect(subject.permitted_commands).to include('gunset')
    end

    it 'should include `unsetg`' do
      expect(subject.permitted_commands).to include('unsetg')
    end

    it 'should include `search`' do
      expect(subject.permitted_commands).to include('search')
    end

    it 'should include `clear`' do
      expect(subject.permitted_commands).to include('clear')
    end

    it 'should include `reload`' do
      expect(subject.permitted_commands).to include('reload')
    end

    it 'should include `help`' do
      expect(subject.permitted_commands).to include('help')
    end

    it 'should include `workspace`' do
      expect(subject.permitted_commands).to include('workspace')
    end

    it 'should include `rebuild_cache`' do
      expect(subject.permitted_commands).to include('rebuild_cache')
    end

    it 'should include `loot`' do
      expect(subject.permitted_commands).to include('loot')
    end

    it 'should include `creds`' do
      expect(subject.permitted_commands).to include('creds')
    end
  end

  describe '#clear' do
    context 'if running on a Windows platform' do
      let(:win_platform?) { true }

      it 'should execute `cls`' do
        subject.clear
        expect(subject).to have_received(:system)
          .with('cls')
          .exactly(1).times
      end
    end

    context 'if not running on a Windows platform' do
      let(:win_platform?) { false }

      it 'should execute `clear`' do
        subject.clear
        expect(subject).to have_received(:system)
          .with('clear')
          .exactly(1).times
      end
    end
  end

  describe '#prompt_for_input' do
    context 'if not on a Windows platform' do
      let(:win_platform?) { false }

      it 'should use a prompt with "wpxf" in underlined and in light blue' do
        subject.prompt_for_input
        expect(Readline).to have_received(:readline)
          .with("#{'wpxf'.underline.light_blue} > ", true)
          .exactly(1).times
      end
    end

    context 'if on a Windows platform' do
      let(:win_platform?) { true }

      it 'should use a prompt with no colour' do
        subject.prompt_for_input
        expect(Readline).to have_received(:readline)
          .with('wpxf > ', true)
          .exactly(1).times
      end
    end

    context 'if a module is loaded' do
      let(:win_platform?) { true }
      let(:module_loaded?) { true }

      it 'should include the module path in the prompt' do
        allow(context).to receive(:module_path).and_return('/path')
        subject.prompt_for_input
        expect(Readline).to have_received(:readline)
          .with('wpxf [/path] > ', true)
          .exactly(1).times
      end
    end

    context 'if an interrupt is signalled whilst awaiting input' do
      it 'should return an empty string' do
        allow(Readline).to receive(:readline).and_raise(SignalException.new('INT'))
        res = subject.prompt_for_input
        expect(res).to eql ''
      end
    end

    context 'if the input is empty' do
      it 'should print a new line to force the next prompt onto a new line' do
        allow(Readline).to receive(:readline).and_raise(SignalException.new('INT'))
        subject.prompt_for_input
        expect(subject).to have_received(:puts).exactly(1).times
      end
    end

    context 'if the input is not empty' do
      it 'should not print a new line' do
        subject.prompt_for_input
        expect(subject).to_not have_received(:puts)
      end

      it 'should return the input' do
        res = subject.prompt_for_input
        expect(res).to eql 'input'
      end
    end
  end

  describe '#can_handle?' do
    context 'if `command` is not a valid method name' do
      it 'should print an error' do
        subject.can_handle? 'in_no_way_valid'
        expect(subject).to have_received(:print_bad)
          .with('"in_no_way_valid" is not a recognised command.')
          .exactly(1).times
      end

      it 'should return false' do
        res = subject.can_handle?('in_no_way_valid')
        expect(res).to be false
      end
    end

    context 'if `command` is not a white listed method name' do
      it 'should print an error' do
        subject.can_handle? 'puts'
        expect(subject).to have_received(:print_bad)
          .with('"puts" is not a recognised command.')
          .exactly(1).times
      end

      it 'should return false' do
        res = subject.can_handle?('puts')
        expect(res).to be false
      end
    end

    context 'if `command` is a valid, white listed method name' do
      it 'should return true' do
        res = subject.can_handle?('use')
        expect(res).to be true
      end
    end
  end

  describe '#correct_number_of_args' do
    context 'if `command` is "workspace"' do
      it 'should return true' do
        res = subject.correct_number_of_args?('workspace', [])
        expect(res).to be true
      end
    end

    context 'if `command` is "creds"' do
      it 'should return true' do
        res = subject.correct_number_of_args?('creds', [])
        expect(res).to be true
      end
    end

    context 'if `command` is "loot"' do
      it 'should return true' do
        res = subject.correct_number_of_args?('loot', [])
        expect(res).to be true
      end
    end

    context 'if `command` is "set"' do
      context 'if `args` has <= 1 value' do
        it 'should return false' do
          res = subject.correct_number_of_args?('set', [])
          expect(res).to be false
        end
      end

      context 'if `args has more than one value`' do
        it 'should return true' do
          res = subject.correct_number_of_args?('set', ['val 1', 'val 2'])
          expect(res).to be true
        end
      end
    end

    context 'if `command` is "unset"' do
      context 'if `args` has <= 1 value' do
        it 'should return false' do
          res = subject.correct_number_of_args?('unset', [])
          expect(res).to be false
        end
      end

      context 'if `args has more than one value`' do
        it 'should return true' do
          res = subject.correct_number_of_args?('unset', ['val 1', 'val 2'])
          expect(res).to be true
        end
      end
    end

    context 'if `command` is "search"' do
      context 'if `args` has <= 1 value' do
        it 'should return false' do
          res = subject.correct_number_of_args?('search', [])
          expect(res).to be false
        end
      end

      context 'if `args has more than one value`' do
        it 'should return true' do
          res = subject.correct_number_of_args?('search', ['val 1', 'val 2'])
          expect(res).to be true
        end
      end
    end

    context 'if the correct number of arguments are specified' do
      it 'should return true' do
        res = subject.correct_number_of_args?('use', ['path'])
        expect(res).to be true
      end
    end

    context 'if the incorrect number of arguments are specified' do
      it 'should print an error' do
        subject.correct_number_of_args?('use', [])
        expect(subject).to have_received(:print_bad)
          .with('0 arguments specified for "use", expected 1.')
          .exactly(1).times
      end

      it 'should return false' do
        res = subject.correct_number_of_args?('use', [])
        expect(res).to be false
      end
    end
  end

  describe '#on_event_emitted' do
    context 'if the event is tagged as verbose' do
      context 'and the current context is not in verbose mode' do
        let(:verbose_context) { false }

        it 'should print nothing' do
          subject.on_event_emitted(verbose: true, type: :success, msg: 'test')
          expect(subject).to_not have_received(:print_bad)
          expect(subject).to_not have_received(:print_good)
          expect(subject).to_not have_received(:print_info)
          expect(subject).to_not have_received(:print_warning)
          expect(subject).to_not have_received(:print_table)
        end
      end
    end

    context 'if the event type is :table' do
      it 'should indent the cursor by 2' do
        subject.on_event_emitted(type: :table, rows: [])
        expect(subject).to have_received(:indent_cursor)
          .with(2)
          .exactly(1).times
      end

      it 'should print the table using the :rows property' do
        subject.on_event_emitted(type: :table, rows: 'rows double')
        expect(subject).to have_received(:print_table)
          .with('rows double', true)
          .exactly(1).times
      end
    end

    context 'if the event type is :error' do
      it 'should invoke #print_bad using the :msg property' do
        subject.on_event_emitted(type: :error, msg: 'test')
        expect(subject).to have_received(:print_bad)
          .with('test')
          .exactly(1).times
      end
    end

    context 'if the event type is :success' do
      it 'should invoke #print_good using the :msg property' do
        subject.on_event_emitted(type: :success, msg: 'test')
        expect(subject).to have_received(:print_good)
          .with('test')
          .exactly(1).times
      end
    end

    context 'if the event type is :info' do
      it 'should invoke #print_info using the :msg property' do
        subject.on_event_emitted(type: :info, msg: 'test')
        expect(subject).to have_received(:print_info)
          .with('test')
          .exactly(1).times
      end
    end

    context 'if the event type is :warning' do
      it 'should invoke #print_warning using the :msg property' do
        subject.on_event_emitted(type: :warning, msg: 'test')
        expect(subject).to have_received(:print_warning)
          .with('test')
          .exactly(1).times
      end
    end
  end

  describe '#normalise_alised_commands' do
    it 'should alias `exit` to `quit`' do
      res = subject.normalise_alised_commands('exit')
      expect(res).to eql 'quit'
    end

    it 'should alias `setg` to `gset`' do
      res = subject.normalise_alised_commands('setg')
      expect(res).to eql 'gset'
    end

    it 'should alias `unsetg` to `gunset`' do
      res = subject.normalise_alised_commands('unsetg')
      expect(res).to eql 'gunset'
    end

    context 'if `command` has no alias' do
      it 'should return itself' do
        res = subject.normalise_alised_commands('yoshi')
        expect(res).to eql 'yoshi'
      end
    end
  end

  describe '#execute_user_command' do
    it 'should normalise any alised commands being used' do
      subject.execute_user_command('test', [])
      expect(subject).to have_received(:normalise_alised_commands)
        .with('test')
        .exactly(1).times
    end

    context 'if the command can be handled' do
      it 'should invoke the command' do
        allow(subject).to receive(:use).and_call_original
        subject.execute_user_command('use', ['/path'])
        expect(subject).to have_received(:use)
          .with('/path')
          .exactly(1).times
      end

      context 'if the command is marked as having no output' do
        it 'should print a new line before and after calling the method' do
          allow(subject).to receive(:use).and_call_original
          subject.execute_user_command('use', ['/path'])
          expect(subject).to have_received(:puts).exactly(2).times
        end
      end
    end
  end

  describe '#check_cache' do
    context 'if the module cache is not valid' do
      before(:each) do
        allow(subject).to receive(:cache_valid?).and_return(false)
      end

      it 'should refresh the module cache' do
        subject.check_cache
        expect(subject).to have_received(:rebuild_cache).exactly(1).times
      end
    end

    context 'if the module cache is valid' do
      before(:each) do
        allow(subject).to receive(:cache_valid?).and_return(true)
      end

      it 'should not refresh the cache' do
        subject.check_cache
        expect(subject).to have_received(:rebuild_cache).exactly(0).times
      end
    end
  end

  describe '#start' do
    before :each, 'setup mocks' do
      allow(subject).to receive(:prompt_for_input).and_return('cmd1 arg1 arg2', 'cmd2 arg1', 'exit')
      allow(subject).to receive(:check_cache)
    end

    it 'should use the first word specified at the prompt as the method name to execute' do
      subject.start
      expect(subject).to have_received(:execute_user_command)
        .with('cmd1', anything).exactly(1).times

      expect(subject).to have_received(:execute_user_command)
        .with('cmd2', anything).exactly(1).times
    end

    it 'should use any words specified at the prompt after the first as args to be used when calling the method' do
      subject.start
      expect(subject).to have_received(:execute_user_command)
        .with('cmd1', %w[arg1 arg2]).exactly(1).times

      expect(subject).to have_received(:execute_user_command)
        .with('cmd2', %w[arg1]).exactly(1).times
    end

    context 'if no command is specified' do
      it 'should not attempt to execute anything' do
        allow(subject).to receive(:prompt_for_input).and_return('', '', 'exit')
        subject.start
        expect(subject).to_not have_received(:execute_user_command)
      end
    end

    context 'if "exit" is specified when prompting for input' do
      it 'should exit the prompt' do
        subject.start
        expect(subject).to have_received(:prompt_for_input).exactly(3).times
      end
    end

    context 'if "quit" is specified when prompting for input' do
      it 'should exit the prompt' do
        allow(subject).to receive(:prompt_for_input).and_return('cmd1', 'cmd2', 'quit')
        subject.start
        expect(subject).to have_received(:prompt_for_input).exactly(3).times
      end
    end

    context 'if an error is raised in the prompt loop' do
      it 'should print an error and continue the loop' do
        allow(subject).to receive(:execute_user_command).and_raise('error')
        subject.start
        expect(subject).to have_received(:print_bad)
          .with('Uncaught error: error')
          .exactly(2).times
      end
    end
  end
end
