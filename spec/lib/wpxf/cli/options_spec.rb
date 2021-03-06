# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/cli/context'
require 'wpxf/cli/options'

describe Wpxf::Cli::Options do
  let(:klass) do
    Class.new do
      include Wpxf::Cli::Options
    end
  end

  let(:subject) { klass.new }
  let(:context) { Wpxf::Cli::Context.new }
  let(:mod) { Wpxf::Module.new }
  let(:aux_module?) { false }
  let(:module_loaded?) { true }

  let(:global_opts) do
    {
      'host' => 'value1',
      'proxy' => 'value2',
      'lhost' => 'test',
      'lport' => '9999'
    }
  end

  before :each, 'setup mocks' do
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:print_info)
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:puts)
    allow(subject).to receive(:global_opts).and_return(global_opts)
    allow(subject).to receive(:context).and_return(context)
    allow(subject).to receive(:refresh_autocomplete_options)
    allow(subject).to receive(:module_loaded?).and_return(module_loaded?)

    allow(mod).to receive(:aux_module?).and_return(aux_module?)

    if context
      allow(context).to receive(:module).and_return(mod)
      allow(context).to receive(:load_payload).and_call_original
    end
  end

  describe '#new' do
    it 'should initialise #global_opts as an empty hash' do
      subject = klass.new
      expect(subject.global_opts).to eql({})
    end
  end

  describe '#unset' do
    context 'if no module is loaded' do
      let(:context) { nil }

      it 'should print an error' do
        subject.unset('test')
        expect(subject).to have_received(:print_bad)
          .with('No module loaded yet')
          .exactly(1).times
      end
    end

    context 'if a module is loaded' do
      it 'should print a message indicating the option was unset' do
        subject.unset('test')
        expect(subject).to have_received(:print_good)
          .with('Unset test')
          .exactly(1).times
      end

      context 'if `name` is "payload"' do
        it 'should set `module.payload` to `nil`' do
          mod.payload = 'test'
          subject.unset('payload')
          expect(mod.payload).to be_nil
        end
      end

      context 'if `name` is not "payload"' do
        it 'should unset the module option' do
          mod.set_option_value('host', 'test')
          expect(mod.get_option_value('host')).to eql 'test'
          subject.unset('host')
          expect(mod.get_option_value('host')).to be_nil
        end
      end
    end
  end

  describe '#apply_global_options' do
    it 'should set the options of `target` using `#global_opts`' do
      expect(mod.get_option_value('host')).to be_nil
      expect(mod.get_option_value('proxy')).to be_nil
      subject.apply_global_options(mod)
      expect(mod.get_option_value('host')).to eql 'value1'
      expect(mod.get_option_value('proxy')).to eql 'value2'
    end

    context 'if `target` is nil' do
      it 'should not set any options' do
        subject.apply_global_options(nil)
        expect(subject).to_not have_received(:global_opts)
      end
    end
  end

  describe '#load_payload' do
    it 'should load the specified payload' do
      subject.load_payload 'reverse_tcp'
      expect(context).to have_received(:load_payload)
        .with('reverse_tcp')
        .exactly(1).times
    end

    it 'should print a message once loaded' do
      subject.load_payload 'reverse_tcp'
      expect(subject).to have_received(:print_good)
        .with("Loaded payload: #{mod.payload}")
    end

    it 'should apply the global options to the payload' do
      subject.load_payload 'reverse_tcp'
      expect(mod.payload.get_option_value('lhost')).to eql 'test'
      expect(mod.payload.get_option_value('lport')).to eql '9999'
    end

    it 'should refresh the auto-complete options' do
      subject.load_payload 'reverse_tcp'
      expect(subject).to have_received(:refresh_autocomplete_options)
    end

    context 'if an error occurs when loading the payload' do
      it 'should print an error' do
        allow(context).to receive(:load_payload).and_raise('error')
        subject.load_payload 'reverse_tcp'
        expect(subject).to have_received(:print_bad)
          .with('Failed to load payload: error')
          .exactly(1).times
      end
    end

    context 'if the module is an auxiliary' do
      let(:aux_module?) { true }

      it 'should print a warning' do
        subject.load_payload 'reverse_tcp'
        expect(subject).to have_received(:print_warning)
          .with('Auxiliary modules do not use payloads')
          .exactly(1).times
      end

      it 'should not attempt to load a payload' do
        subject.load_payload 'reverse_tcp'
        expect(context).to_not have_received(:load_payload)
      end
    end
  end

  describe '#set_option_value' do
    it 'should set the specified module option to `value`' do
      subject.set_option_value('host', 'set_option_value')
      expect(mod.get_option_value('host')).to eql 'set_option_value'
    end

    context 'if the option does not exist' do
      it 'should print a warning' do
        subject.set_option_value('asdasdasd', 'value')
        expect(subject).to have_received(:print_warning)
          .with('"asdasdasd" is not a valid option')
          .exactly(1).times
      end
    end

    context 'if the specified value is invalid' do
      it 'should print an error' do
        subject.set_option_value('port', 'invalid')
        expect(subject).to have_received(:print_bad)
          .with('"invalid" is not a valid value')
          .exactly(1).times
      end
    end

    context 'if the option was successfully set' do
      it 'should print a confirmation' do
        subject.set_option_value('host', 'set_option_value')
        expect(subject).to have_received(:print_good)
          .with('Set host => set_option_value')
          .exactly(1).times
      end
    end

    context 'if `silent` is true' do
      it 'should not print any messages' do
        subject.set_option_value('host', 'set_option_value', true)
        expect(subject).to_not have_received(:print_good)

        subject.set_option_value('port', 'invalid', true)
        expect(subject).to_not have_received(:print_bad)

        subject.set_option_value('asdasdasd', 'value', true)
        expect(subject).to_not have_received(:print_warning)
      end
    end
  end

  describe '#gset' do
    it 'should add the key-value pair to #global_opts' do
      subject.gset('test', 'value')
      expect(subject.global_opts).to include('test' => 'value')
    end

    it 'should print a confirmation' do
      subject.gset('test', 'value')
      expect(subject).to have_received(:print_good)
        .with('Globally set the value of test to value')
        .exactly(1).times
    end

    context 'if a module is loaded' do
      it 'should set the option value on the current module' do
        subject.gset('host', 'test')
        expect(mod.get_option_value('host')).to eql 'test'
      end
    end

    context 'if multiple `args` are passed' do
      it 'should concatenate them with a space and use it as the value' do
        subject.gset('host', 'test', 'test2')
        expect(mod.get_option_value('host')).to eql 'test test2'
      end
    end

    context 'if trying to globally set the payload' do
      it 'should print a warning' do
        subject.gset('payload', 'test')
        expect(subject).to have_received(:print_warning)
          .with('The payload cannot be globally set')
          .exactly(1).times
      end

      it 'should not register the global option value' do
        subject.gset('payload', 'test')
        expect(subject.global_opts['payload']).to be_nil
      end
    end
  end

  describe '#gunset' do
    it 'should remove the specified global option' do
      subject.gset('test', 'value')
      subject.gunset('test')
      expect(subject.global_opts['test']).to be_nil
    end

    it 'should print a confirmation' do
      subject.gset('test', 'value')
      subject.gunset('test')
      expect(subject).to have_received(:print_good)
        .with('Removed the global setting for test')
        .exactly(1).times
    end

    context 'if a module is loaded' do
      it 'should unset the option on the current module' do
        subject.gset('host', 'value')
        subject.gunset('host')
        expect(mod.get_option_value('host')).to be_nil
      end
    end
  end

  describe '#set' do
    context 'if a module is not loaded' do
      let(:module_loaded?) { false }

      it 'should not set an option or payload' do
        allow(subject).to receive(:load_payload)
        allow(subject).to receive(:set_option_value)

        subject.set('host', 'test')
        expect(subject).to_not have_received(:load_payload)
        expect(subject).to_not have_received(:set_option_value)
      end
    end

    context 'if trying to set the payload' do
      it 'should load the specified payload' do
        subject.set('payload', 'reverse_tcp')
        expect(mod.payload).to be_a Wpxf::Payloads::ReverseTcp
      end
    end

    context 'if trying to set an option' do
      it 'should set the specified option' do
        subject.set('host', 'test')
        expect(mod.get_option_value('host')).to eql 'test'
      end
    end

    context 'if multiple `args` are passed' do
      it 'should concatenate them with a space and use it as the value' do
        subject.set('host', 'test', 'value')
        expect(mod.get_option_value('host')).to eql 'test value'
      end
    end

    context 'if an error occurs when setting the option or payload' do
      it 'should print an error' do
        allow(subject).to receive(:set_option_value).and_raise('option error')
        allow(subject).to receive(:load_payload).and_raise('payload error')

        subject.set('host', 'test')
        expect(subject).to have_received(:print_bad)
          .with('Failed to set host: option error')
          .exactly(1).times

        subject.set('payload', 'test')
        expect(subject).to have_received(:print_bad)
          .with('Failed to set payload: payload error')
          .exactly(1).times
      end
    end
  end
end
