# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/helpers/export'

describe Wpxf::Helpers::Export do
  let(:klass) do
    Class.new(Wpxf::Module) do
      include Wpxf::Helpers::Export
      include Wpxf::Db::Loot
    end
  end

  let(:subject) { klass.new }

  describe '#register_export_path_option' do
    it 'should register the export_path option' do
      expect(subject.get_option('export_path')).to be_nil
      subject.register_export_path_option(false)
      expect(subject.get_option('export_path')).to_not be_nil
    end

    it 'should use the {required} argument to determine if the option should be required' do
      subject.register_export_path_option(false)
      expect(subject.get_option('export_path').required?).to be false

      subject.register_export_path_option(true)
      expect(subject.get_option('export_path').required?).to be true
    end

    it 'should return the new option' do
      expect(subject.register_export_path_option(false)).to be_a Wpxf::Option
      expect(subject.register_export_path_option(false).name).to eql 'export_path'
    end
  end

  describe '#export_path' do
    context 'if the export_path option has no value' do
      it 'should return nil' do
        subject.register_export_path_option(false)
        expect(subject.export_path).to be_nil
      end
    end

    context 'if a value has been specified for export_path' do
      it 'should return the expanded path' do
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('/tmp').and_return('expanded_value')
        subject.register_export_path_option(false)
        subject.set_option_value('export_path', '/tmp')
        expect(subject.export_path).to eql 'expanded_value'
        expect(File).to have_received(:expand_path).with('/tmp').exactly(1).times
      end
    end
  end

  describe '#generate_unique_filename' do
    it 'should generate a filename using the current timestamp' do
      filename = subject.generate_unique_filename('')
      expect(filename).to match(/\d{4}\-\d{2}\-\d{2}_\d{2}\-\d{2}\-\d{2}$/)
    end

    it 'should append the file extension to the filename' do
      filename = subject.generate_unique_filename('.txt')
      expect(filename).to match(/\.txt$/)
    end

    it 'should ensure the home loot directory is created' do
      allow(File).to receive(:directory?).and_return(false)
      allow(FileUtils).to receive(:mkdir_p)
      allow(Dir).to receive(:home).and_return('/home')
      subject.generate_unique_filename('.txt')
      expect(FileUtils).to have_received(:mkdir_p)
        .with('/home/.wpxf/loot')
        .exactly(1).times
    end
  end

  describe '#export_and_log_loot' do
    before :each, 'setup mocks' do
      allow(File).to receive(:write)
      allow(subject).to receive(:generate_unique_filename).and_return('filename')
      subject.set_option_value('host', '127.0.0.1')
    end

    it 'should write the content to a file in the home loot directory' do
      subject.export_and_log_loot('content', 'description', 'type')
      expect(File).to have_received(:write)
        .with('filename', 'content')
        .exactly(1).times
    end

    it 'should create a new loot item' do
      subject.export_and_log_loot('content', 'description', 'type')
      loot_count = Wpxf::Models::LootItem.count(
        path: 'filename',
        notes: 'description',
        type: 'type',
        host: '127.0.0.1',
        port: 80
      )

      expect(loot_count).to eql 1
    end

    it 'should return a loot item' do
      loot = subject.export_and_log_loot('content', 'description', 'type')
      expect(loot).to be_a Wpxf::Models::LootItem
    end
  end
end
