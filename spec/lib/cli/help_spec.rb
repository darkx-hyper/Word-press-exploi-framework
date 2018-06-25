# frozen_string_literal: true

require_relative '../../spec_helper'
require 'cli/context'
require 'cli/help'

describe Cli::Help do
  let :subject do
    Class.new do
      include Cli::Help

      def indent_cursor(_level = nil)
        yield
      end

      def module_loaded?(_quiet = true)
        !context.module.nil?
      end
    end.new
  end

  before :each, 'setup mocks' do
    allow(subject).to receive(:indent_cursor).and_call_original
    allow(subject).to receive(:print_std)
    allow(subject).to receive(:puts)
    allow(subject).to receive(:print_table)
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_module_table)

    context = Cli::Context.new
    allow(subject).to receive(:context).and_return(context)

    Models::Module.create(
      path: 'exploit/shell/admin_shell_upload',
      type: 'exploit',
      name: 'Admin Shell Upload',
      class_name: 'Wpxf::Exploit::AdminShellUpload'
    )

    Models::Module.create(
      path: 'auxiliary/dos/load_scripts_dos',
      type: 'auxiliary',
      name: 'WordPress "load-scripts.php" DoS',
      class_name: 'Wpxf::Auxiliary::LoadScriptsDos'
    )
  end

  describe '#print_options' do
    let(:mod) { Wpxf::Module.new }

    before :each, 'setup mocks' do
      mod.register_options(
        [
          Wpxf::StringOption.new(name: 'test1'),
          Wpxf::StringOption.new(name: 'test4')
        ]
      )

      mod.register_advanced_options(
        [
          Wpxf::StringOption.new(name: 'test2'),
          Wpxf::StringOption.new(name: 'test3')
        ]
      )

      allow(subject).to receive(:print_options_table)
    end

    it 'should print a "Module options:" header' do
      subject.print_options(mod)
      expect(subject).to have_received(:print_std)
        .with('Module options:')
        .exactly(1).times
    end

    it 'should print the module options' do
      opts = subject.module_options(mod, false)
      subject.print_options(mod)

      expect(subject).to have_received(:print_options_table)
        .with(mod, opts)
        .exactly(1).times
    end
  end

  describe '#print_payload_options' do
    let(:payload) { Wpxf::Payload.new }

    before :each, 'setup mocks' do
      payload.register_options(
        [
          Wpxf::StringOption.new(name: 'test1'),
          Wpxf::StringOption.new(name: 'test4')
        ]
      )

      allow(subject).to receive(:print_options_table)
    end

    it 'should print a "Payload options:" header' do
      subject.print_payload_options(payload)
      expect(subject).to have_received(:print_std)
        .with('Payload options:')
        .exactly(1).times
    end

    it 'should print the payload options' do
      subject.print_options(payload)

      expect(subject).to have_received(:print_options_table)
        .with(payload, payload.options)
        .exactly(1).times
    end
  end

  describe '#show_options' do
    before :each, 'setup mocks' do
      allow(subject).to receive(:print_options)
      allow(subject).to receive(:print_payload_options)
    end

    context 'if a module is loaded' do
      before :each, 'setup module' do
        subject.context.load_module 'exploit/shell/admin_shell_upload'
      end

      it 'should print the module options' do
        subject.show_options
        expect(subject).to have_received(:print_options)
          .with(subject.context.module)
          .exactly(1).times
      end

      context 'if a payload is loaded' do
        it 'should print the payload options' do
          subject.context.load_payload 'reverse_tcp'
          subject.show_options

          expect(subject).to have_received(:print_payload_options)
            .with(subject.context.module.payload)
            .exactly(1).times
        end
      end
    end

    context 'if a module is not loaded' do
      it 'should not print anything' do
        subject.show_options

        expect(subject).to_not have_received(:print_options)
        expect(subject).to_not have_received(:print_payload_options)
      end
    end
  end

  describe '#print_options_table' do
    it 'should print a table using the headers from #empty_option_table_data' do
      headers = subject.empty_option_table_data
      subject.print_options_table Wpxf::Module.new, []

      expect(subject).to have_received(:print_table)
        .with(headers)
        .exactly(1).times
    end

    it 'should include each option in the table' do
      subject.print_options_table Wpxf::Module.new, [
        Wpxf::StringOption.new(name: 'test1', desc: 'test1 desc'),
        Wpxf::StringOption.new(name: 'test2', required: true, desc: 'test2 desc')
      ]

      expect(subject).to have_received(:print_table)
        .with(
          [
            {
              name: 'Name',
              value: 'Current Setting',
              req: 'Required',
              desc: 'Description'
            },
            {
              name: 'test1',
              value: nil,
              req: false,
              desc: 'test1 desc'
            },
            {
              name: 'test2',
              value: nil,
              req: true,
              desc: 'test2 desc'
            }
          ]
        )
    end
  end

  describe '#print_advanced_option' do
    let(:mod) { Wpxf::Module.new }
    let(:opt) { Wpxf::StringOption.new(name: 'test', desc: 'test desc') }

    before :each, 'setup mocks' do
      mod.register_option(opt)
      mod.set_option_value('test', 'value')
    end

    it 'should print the name of the option' do
      subject.print_advanced_option(mod, opt)
      expect(subject).to have_received(:print_std)
        .with('Name: test')
    end

    it 'should print the current setting of the option' do
      subject.print_advanced_option(mod, opt)
      expect(subject).to have_received(:print_std)
        .with('Current setting: value')
    end

    it 'should print whether the option is required' do
      subject.print_advanced_option(mod, opt)
      expect(subject).to have_received(:print_std)
        .with('Required: false')
    end

    it 'should print the description of the option' do
      subject.print_advanced_option(mod, opt)
      expect(subject).to have_received(:print_std)
        .with('Description: test desc')
    end
  end

  describe '#show_advanced_options' do
    before :each, 'setup mocks' do
      allow(subject).to receive(:print_advanced_option)
    end

    context 'if a module is loaded' do
      before :each, 'setup module' do
        subject.context.load_module 'exploit/shell/admin_shell_upload'
        subject.context.module.options = []
        subject.context.module.register_options(
          [
            Wpxf::StringOption.new(name: 'test1'),
            Wpxf::StringOption.new(name: 'test4')
          ]
        )

        subject.context.module.register_advanced_options(
          [
            Wpxf::StringOption.new(name: 'test2'),
            Wpxf::StringOption.new(name: 'test3')
          ]
        )
      end

      it 'should print the advanvced module options' do
        subject.show_advanced_options
        expect(subject).to have_received(:print_advanced_option).exactly(2).times

        expect(subject).to have_received(:print_advanced_option)
          .with(subject.context.module, subject.context.module.options[2])
          .exactly(1).times

        expect(subject).to have_received(:print_advanced_option)
          .with(subject.context.module, subject.context.module.options[3])
          .exactly(1).times
      end
    end

    context 'if a module is not loaded' do
      it 'should not print anything' do
        subject.show_advanced_options
        expect(subject).to_not have_received(:print_advanced_option)
      end
    end
  end

  describe '#help' do
    it 'should print the contents of `data/json/commands.json` as a table' do
      base_path = File.expand_path(File.join(__dir__, '..', '..', '..'))
      commands_path = File.join(base_path, 'data', 'json', 'commands.json')
      content = JSON.parse(File.read(commands_path))
      data = content['data']
      data.unshift('cmd' => 'Command', 'desc' => 'Description')

      subject.help
      expect(subject).to have_received(:print_table)
        .with(data)
        .exactly(1).times
    end

    it 'should indent the cursor by 2 positions' do
      subject.help
      expect(subject).to have_received(:indent_cursor)
        .with(2)
        .exactly(1).times
    end
  end

  describe '#show_exploits' do
    it 'should notify the user how many exploits were found' do
      subject.show_exploits
      expect(subject).to have_received(:print_good)
        .with('1 Exploits')
    end

    it 'should call #print_module_table with an array of hashes' do
      subject.show_exploits
      expect(subject).to have_received(:print_module_table)
        .with([{ path: 'exploit/shell/admin_shell_upload', title: 'Admin Shell Upload' }])
        .exactly(1).times
    end
  end

  describe 'show_auxiliary' do
    it 'should notify the user how many auxiliaries were found' do
      subject.show_auxiliary
      expect(subject).to have_received(:print_good)
        .with('1 Auxiliaries')
    end

    it 'should call #print_module_table with an array of hashes' do
      subject.show_auxiliary
      expect(subject).to have_received(:print_module_table)
        .with([{ path: 'auxiliary/dos/load_scripts_dos', title: 'WordPress "load-scripts.php" DoS' }])
        .exactly(1).times
    end
  end

  describe '#show' do
    before :each, 'setup mocks' do
      allow(subject).to receive(:show_options)
      allow(subject).to receive(:show_advanced_options)
      allow(subject).to receive(:show_exploits)
      allow(subject).to receive(:show_auxiliary)
    end

    context 'if `target` == `options`' do
      it 'should invoke `show_options`' do
        subject.show 'options'
        expect(subject).to have_received(:show_options).exactly(1).times
      end
    end

    context 'if `target` == `advanced`' do
      it 'should invoke `show_advanced_options`' do
        subject.show 'advanced'
        expect(subject).to have_received(:show_advanced_options).exactly(1).times
      end
    end

    context 'if `target` == `exploits`' do
      it 'should invoke `show_exploits`' do
        subject.show 'exploits'
        expect(subject).to have_received(:show_exploits).exactly(1).times
      end
    end

    context 'if `target` == `auxiliary`' do
      it 'should invoke `show_auxiliary`' do
        subject.show 'auxiliary'
        expect(subject).to have_received(:show_auxiliary).exactly(1).times
      end
    end

    context 'if `target` is not recognised' do
      it 'should alert the user it is not a valid argument' do
        subject.show 'invalid'
        expect(subject).to have_received(:print_bad)
          .with('"invalid" is not a valid argument')
          .exactly(1).times
      end
    end
  end

  describe '#module_options' do
    let(:mod) { Wpxf::Module.new }
    before :each, 'setup mocks' do
      mod.options = []
      mod.register_options(
        [
          Wpxf::StringOption.new(name: 'test4'),
          Wpxf::StringOption.new(name: 'test1')
        ]
      )

      mod.register_advanced_options(
        [
          Wpxf::StringOption.new(name: 'test3'),
          Wpxf::StringOption.new(name: 'test2')
        ]
      )
    end

    context 'if `advanced` is true' do
      it 'should return the advanced options of `mod`' do
        res = subject.module_options(mod, true)
        expect(res.length).to eql 2
        expect(res[0]).to be_a Wpxf::Option
        expect(res[1]).to be_a Wpxf::Option
      end

      it 'should sort the options by name' do
        res = subject.module_options(mod, true)
        expect(res[0].name).to eql 'test2'
        expect(res[1].name).to eql 'test3'
      end
    end

    context 'if `advanced` is false' do
      it 'should return the normal options of `mod`' do
        res = subject.module_options(mod, false)
        expect(res.length).to eql 2
        expect(res[0]).to be_a Wpxf::Option
        expect(res[1]).to be_a Wpxf::Option
      end

      it 'should sort the options by name' do
        res = subject.module_options(mod, false)
        expect(res[0].name).to eql 'test1'
        expect(res[1].name).to eql 'test4'
      end
    end
  end

  describe '#empty_option_table_data' do
    it 'should return an array with the option table headers' do
      expect(subject.empty_option_table_data).to eql(
        [{
          name: 'Name',
          value: 'Current Setting',
          req: 'Required',
          desc: 'Description'
        }]
      )
    end
  end

  describe '#option_table_row' do
    let(:mod) { Wpxf::Module.new }

    before :each, 'setup mocks' do
      mod.register_options(
        [
          Wpxf::StringOption.new(name: 'test1', desc: 'test1 desc'),
          Wpxf::StringOption.new(name: 'test4')
        ]
      )

      mod.register_advanced_options(
        [
          Wpxf::StringOption.new(name: 'test2'),
          Wpxf::StringOption.new(name: 'test3')
        ]
      )
    end

    it 'should return a hash containing the option name' do
      opt = mod.options.select { |o| o.name == 'test1' }
      res = subject.option_table_row(mod, opt[0])

      expect(res).to include(:name)
      expect(res[:name]).to eql 'test1'
    end

    it 'should return a hash containing the option description' do
      opt = mod.options.select { |o| o.name == 'test1' }
      res = subject.option_table_row(mod, opt[0])

      expect(res).to include(:desc)
      expect(res[:desc]).to eql 'test1 desc'
    end

    it 'should return a hash containing the required flag' do
      opt = mod.options.select { |o| o.name == 'test1' }
      res = subject.option_table_row(mod, opt[0])

      expect(res).to include(:req)
      expect(res[:req]).to be false
    end

    it 'should return a hash containing the option value' do
      mod.set_option_value('test1', 'test')
      opt = mod.options.select { |o| o.name == 'test1' }
      res = subject.option_table_row(mod, opt[0])

      expect(res).to include(:value)
      expect(res[:value]).to eql 'test'
    end
  end
end
