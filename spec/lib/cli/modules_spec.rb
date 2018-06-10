# frozen_string_literal: true

require_relative '../../spec_helper'
require 'cli/console'

describe Cli::Modules do
  let(:subject) { Cli::Console.new }

  before :each, 'setup mocks' do
    allow(subject).to receive('print_good')
    allow(subject).to receive('print_info')
    allow(subject).to receive('print_bad')
    allow(subject).to receive('puts')
  end

  describe '#new' do
    it 'should initialise `context_stack` with an empty array' do
      expect(subject.context_stack).to eql []
    end
  end

  describe '#use' do
    it 'should load a new module into the current context' do
      subject.use('exploit/shell/admin_shell_upload')
      expect(subject.context.module.module_name).to eql 'Admin Shell Upload'
    end

    it 'should subscribe to the event emitter' do
      subject.use('exploit/shell/admin_shell_upload')
      subject.context.module.emit_info('test')
      expect(subject).to have_received(:print_info).with('test').exactly(1).times
    end

    it 'should set the `active_workspace` of the module' do
      subject.use('exploit/shell/admin_shell_upload')
      expect(subject.context.module.active_workspace.name).to eql 'default'
    end

    it 'should notify the user the module was loaded' do
      subject.use('exploit/shell/admin_shell_upload')
      mod = subject.context.module
      expect(subject).to have_received(:print_good).with("Loaded module: #{mod}").exactly(1).times
    end

    it 'should emit the usage info' do
      module_double = double('module')
      allow(module_double).to receive(:subscribe)
      allow(module_double).to receive(:event_emitter).and_return(module_double)
      allow(module_double).to receive(:emit_usage_info)
      allow(module_double).to receive(:active_workspace=)

      allow_any_instance_of(Cli::Context).to receive(:load_module).and_return(module_double)
      allow(subject).to receive(:refresh_autocomplete_options)

      subject.use('exploit/shell/admin_shell_upload')
      expect(module_double).to have_received(:emit_usage_info).exactly(1).times
    end

    it 'should push the new context on top of the stack' do
      subject.use('auxiliary/dos/load_scripts_dos')
      expect(subject.context.module.module_name).to eql 'WordPress "load-scripts.php" DoS'

      subject.use('exploit/shell/admin_shell_upload')
      expect(subject.context.module.module_name).to eql 'Admin Shell Upload'
    end

    it 'should set globally specified option values' do
      subject.gset('host', 'rspec test')
      subject.use('exploit/shell/admin_shell_upload')

      value = subject.context.module.datastore['host']
      expect(value).to eql 'rspec test'
    end

    it 'should refresh the auto-complete options' do
      allow(subject).to receive(:refresh_autocomplete_options)
      subject.use('exploit/shell/admin_shell_upload')
      expect(subject).to have_received(:refresh_autocomplete_options).exactly(1).times
    end

    context 'if the module fails to load' do
      it 'should print an error' do
        allow_any_instance_of(Cli::Context).to receive(:load_module).and_return(nil)
        subject.use('exploit/shell/admin_shell_upload')
        expect(subject).to have_received(:print_bad).exactly(1).times
      end
    end
  end

  describe '#reload' do
    it 'should reload the current module' do
      subject.use('exploit/shell/admin_shell_upload')
      original = subject.context.module

      subject.reload
      expect(subject.context.module).to_not equal original
      expect(subject.context.module.module_name).to eql original.module_name
    end

    it 'should subscribe to the event emitter' do
      subject.use('exploit/shell/admin_shell_upload')
      subject.reload
      subject.context.module.emit_info('test')
      expect(subject).to have_received(:print_info).with('test').exactly(1).times
    end

    it 'should set the `active_workspace` of the module' do
      subject.use('exploit/shell/admin_shell_upload')
      subject.reload
      expect(subject.context.module.active_workspace.name).to eql 'default'
    end

    it 'should notify the user the module was reloaded' do
      subject.use('exploit/shell/admin_shell_upload')
      subject.reload
      mod = subject.context.module
      expect(subject).to have_received(:print_good).with("Reloaded module: #{mod}").exactly(1).times
    end

    it 'should set globally specified option values' do
      subject.gset('host', 'rspec test')
      subject.use('exploit/shell/admin_shell_upload')
      subject.reload

      value = subject.context.module.datastore['host']
      expect(value).to eql 'rspec test'
    end

    context 'if the module fails to load' do
      it 'should print an error' do
        allow_any_instance_of(Cli::Context).to receive(:reload).and_return(nil)
        subject.use('exploit/shell/admin_shell_upload')
        subject.reload
        expect(subject).to have_received(:print_bad).exactly(1).times
      end
    end

    context 'if no module is loaded' do
      it 'should display an error' do
        subject.reload
        expect(subject).to have_received(:print_bad).with('No module loaded yet').exactly(1).times
      end
    end
  end

  describe '#context' do
    it 'should return the context on top of the `context_stack`' do
      subject.context_stack.push(1)
      subject.context_stack.push(2)
      expect(subject.context).to eql 2
    end

    context 'if `context_stack` is empty' do
      it 'should return `nil`' do
        expect(subject.context).to be_nil
      end
    end
  end

  describe '#back' do
    it 'should pop the `context_stack`' do
      subject.use('exploit/shell/admin_shell_upload')
      subject.use('auxiliary/dos/load_scripts_dos')
      expect(subject.context.module).to be_a(Wpxf::Auxiliary::LoadScriptsDos)
      subject.back
      expect(subject.context.module).to be_a(Wpxf::Exploit::AdminShellUpload)
    end

    it 'should refresh the auto-complete options' do
      subject.use('exploit/shell/admin_shell_upload')
      subject.use('auxiliary/dos/load_scripts_dos')
      allow(subject).to receive(:refresh_autocomplete_options)
      subject.back
      expect(subject).to have_received(:refresh_autocomplete_options).exactly(1).times
    end

    context 'if a module is in the new context' do
      it 'should set the `active_workspace`' do
        subject.use('auxiliary/dos/load_scripts_dos')
        subject.use('exploit/shell/admin_shell_upload')
        subject.back

        mod = subject.context.module
        expect(mod.active_workspace.name).to eql 'default'
      end
    end
  end

  describe '#module_name_from_class' do
    it 'should return the module name from its metadata' do
      name = subject.module_name_from_class(Wpxf::Exploit::AdminShellUpload)
      expect(name).to eql 'Admin Shell Upload'
    end
  end

  describe '#print_module_table' do
    before :each, 'setup spies' do
      allow(subject).to receive(:indent_cursor).and_call_original
      allow(subject).to receive(:print_table)
    end

    it 'should print a table with the headers `Module` and `Title`' do
      modules = [
        { path: 'a', title: 'title a' },
        { path: 'b', title: 'title b' },
        { path: 'c', title: 'title c' }
      ]

      expected_table = [
        { path: 'Module', title: 'Title' },
        { path: 'a', title: 'title a' },
        { path: 'b', title: 'title b' },
        { path: 'c', title: 'title c' }
      ]

      subject.print_module_table modules
      expect(subject).to have_received(:print_table).with(expected_table).exactly(1).times
    end

    it 'should sort the table items by the `Module` column' do
      modules = [
        { path: 'c', title: 'title c' },
        { path: 'a', title: 'title a' },
        { path: 'b', title: 'title b' }
      ]

      expected_table = [
        { path: 'Module', title: 'Title' },
        { path: 'a', title: 'title a' },
        { path: 'b', title: 'title b' },
        { path: 'c', title: 'title c' }
      ]

      subject.print_module_table modules
      expect(subject).to have_received(:print_table).with(expected_table).exactly(1).times
    end

    it 'should indent the cursor by 2 when printing the table' do
      modules = [
        { path: 'c', title: 'title c' },
        { path: 'a', title: 'title a' },
        { path: 'b', title: 'title b' }
      ]

      subject.print_module_table modules
      expect(subject).to have_received(:indent_cursor).with(2).exactly(1).times
    end
  end
end
