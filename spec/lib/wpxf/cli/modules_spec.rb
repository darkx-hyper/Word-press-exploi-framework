# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/cli/console'

describe Wpxf::Cli::Modules do
  let(:subject) { Wpxf::Cli::Console.new }

  before :each, 'setup mocks' do
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:print_info)
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:puts)
    allow(subject).to receive(:indent_cursor).and_call_original
    allow(subject).to receive(:print_table)

    Wpxf::Models::Module.create(
      path: 'exploit/shell/admin_shell_upload',
      type: 'exploit',
      name: 'Admin Shell Upload',
      class_name: 'Wpxf::Exploit::AdminShellUpload'
    )

    Wpxf::Models::Module.create(
      path: 'auxiliary/dos/load_scripts_dos',
      type: 'auxiliary',
      name: 'WordPress "load-scripts.php" DoS',
      class_name: 'Wpxf::Auxiliary::LoadScriptsDos'
    )
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

      allow_any_instance_of(Wpxf::Cli::Context).to receive(:load_module).and_return(module_double)
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
        allow_any_instance_of(Wpxf::Cli::Context).to receive(:load_module).and_return(nil)
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
        allow_any_instance_of(Wpxf::Cli::Context).to receive(:reload).and_return(nil)
        subject.use('exploit/shell/admin_shell_upload')
        subject.reload
        expect(subject).to have_received(:print_bad).exactly(1).times
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

  describe '#search_modules' do
    before :each, 'setup modules' do
      Wpxf::Models::Module.create(path: '/test1', name: 'Test 1', type: 'exploit', class_name: 'Test1')
      Wpxf::Models::Module.create(path: '/test2', name: 'Test 2 - Plugin', type: 'auxiliary', class_name: 'Test2')
      Wpxf::Models::Module.create(path: '/test3', name: 'TestPlugin 3', type: 'exploit', class_name: 'Test3')
      Wpxf::Models::Module.create(path: '/test4', name: 'Test 4', type: 'exploit', class_name: 'Test4')
      Wpxf::Models::Module.create(path: '/test5', name: 'Test PLUGIN 5', type: 'exploit', class_name: 'Test5')
    end

    it 'should return an item for each module with a name like `%args%`' do
      mods = subject.search_modules(['1'])
      expect(mods.length).to eql 1
    end

    it 'should use a case insensitive search' do
      mods = subject.search_modules(['plugin'])
      expect(mods.length).to eql 3
    end

    describe 'each item returned' do
      it 'should have a :path' do
        mods = subject.search_modules(['plugin'])
        expect(mods[0][:path]).to eql '/test2'
        expect(mods[1][:path]).to eql '/test3'
        expect(mods[2][:path]).to eql '/test5'
      end

      it 'should have a :title' do
        mods = subject.search_modules(['plugin'])
        expect(mods[0][:title]).to eql 'Test 2 - Plugin'
        expect(mods[1][:title]).to eql 'TestPlugin 3'
        expect(mods[2][:title]).to eql 'Test PLUGIN 5'
      end
    end
  end

  describe '#print_module_table' do
    it 'should print the modules in a table' do
      subject.print_module_table([{ path: 'test1', title: 'test1' }])
      expect(subject).to have_received(:print_table)
    end

    it 'should insert column headers before printing the table' do
      expected = [
        { path: 'Module', title: 'Title' },
        { path: 'test1', title: 'test1' }
      ]

      subject.print_module_table([{ path: 'test1', title: 'test1' }])
      expect(subject).to have_received(:print_table).with(expected)
    end

    it 'should sort the modules by the path before printing the table' do
      expected = [
        { path: 'Module', title: 'Title' },
        { path: 'test1', title: 'test1' },
        { path: 'test2', title: 'test2' },
        { path: 'test3', title: 'test3' }
      ]

      subject.print_module_table(
        [
          { path: 'test2', title: 'test2' },
          { path: 'test3', title: 'test3' },
          { path: 'test1', title: 'test1' }
        ]
      )

      expect(subject).to have_received(:print_table).with(expected)
    end
  end

  describe '#search' do
    before :each, 'setup modules' do
      Wpxf::Models::Module.create(path: '/test1', name: 'Test 1', type: 'exploit', class_name: 'Test1')
      Wpxf::Models::Module.create(path: '/test2', name: 'Test 2 - Plugin', type: 'auxiliary', class_name: 'Test2')
      Wpxf::Models::Module.create(path: '/test3', name: 'TestPlugin 3', type: 'exploit', class_name: 'Test3')
      Wpxf::Models::Module.create(path: '/test4', name: 'Test 4', type: 'exploit', class_name: 'Test4')
      Wpxf::Models::Module.create(path: '/test5', name: 'Test PLUGIN 5', type: 'exploit', class_name: 'Test5')
    end

    context 'if modules are found' do
      it 'should print the number of matching modules found' do
        subject.search 'plugin'
        expect(subject).to have_received(:print_good).with('3 Results for "plugin"')
      end

      it 'should print the results in a table' do
        allow(subject).to receive(:print_module_table)
        subject.search 'Test 1'
        expect(subject).to have_received(:print_module_table).with(
          [
            { path: '/test1', title: 'Test 1' }
          ]
        )
      end
    end

    context 'if no modules are found' do
      it 'should notify the user no results were found' do
        subject.search 'no', 'results'
        expect(subject).to have_received(:print_bad).with('No results for "no results"')
      end
    end
  end

  describe '#reset_context_stack' do
    it 'should reset the context stack to an empty array' do
      subject.context_stack = [1, 2, 3]
      expect(subject.context_stack).to eql [1, 2, 3]
      subject.reset_context_stack
      expect(subject.context_stack).to eql []
      expect(subject.context).to be_nil
    end

    it 'should re-setup the auto complete options' do
      allow(subject).to receive(:setup_auto_complete)
      subject.reset_context_stack
      expect(subject).to have_received(:setup_auto_complete)
    end
  end
end
