# frozen_string_literal: true

require_relative '../../spec_helper'
require 'cli/module_cache'
require 'modules'

describe Cli::ModuleCache do
  let :subject do
    Class.new do
      include Cli::ModuleCache

      def initialize
        super
      end
    end.new
  end

  before(:each, 'setup mocks') do
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:print_info)
    allow(subject).to receive(:context)
    allow(subject).to receive(:reset_context_stack)
  end

  describe '#new' do
    it 'should initialise `current_version_number` with the contents of the VERSION file' do
      version_path = File.join(File.dirname(__FILE__), '../../../VERSION')
      version = File.read(version_path)
      expect(version).to match(/(\d\.?)+/)
      expect(subject.current_version_number).to eql version
    end
  end

  describe '#cache_valid?' do
    context 'if no version has been logged previously' do
      it 'should return false' do
        Models::Log.truncate
        expect(subject.cache_valid?).to be false
      end
    end

    context 'if the previously logged version is older than the current' do
      it 'should return false' do
        Models::Log.create(key: 'version', value: '1.0')
        subject.current_version_number = '1.1'
        expect(subject.cache_valid?).to be false
      end
    end

    context 'if the current version is equal to the logged version' do
      it 'should return true' do
        Models::Log.create(key: 'version', value: '1.0')
        subject.current_version_number = '1.0'
        expect(subject.cache_valid?).to be true
      end
    end

    context 'if the current version is lower than the logged version' do
      it 'should return false' do
        Models::Log.create(key: 'version', value: '1.2')
        subject.current_version_number = '1.1'
        expect(subject.cache_valid?).to be false
      end
    end
  end

  describe '#create_module_models' do
    context 'if `type` is exploit' do
      it 'should create a {Models::Module} for each class in the Wpxf::Exploit namespace' do
        modules = Wpxf::Exploit.constants.select do |c|
          Wpxf::Exploit.const_get(c).is_a? Class
        end

        subject.create_module_models 'exploit'
        exploit_count = Models::Module.where(type: 'exploit').count
        expect(exploit_count).to eql modules.count
      end
    end

    context 'if `type` is not exploit' do
      it 'should create a {Models::Module} for each class in the Wpxf::Exploit namespace' do
        modules = Wpxf::Auxiliary.constants.select do |c|
          Wpxf::Auxiliary.const_get(c).is_a? Class
        end

        subject.create_module_models 'auxiliary'
        exploit_count = Models::Module.where(type: 'auxiliary').count
        expect(exploit_count).to eql modules.count
      end
    end
  end

  describe '#refresh_version_log' do
    context 'if a version log already exists' do
      it 'should update the existing entry' do
        Models::Log.create(key: 'version', value: '5')
        expect(Models::Log.count).to eql 1

        subject.current_version_number = '99'
        subject.refresh_version_log
        expect(Models::Log.count).to eql 1

        log = Models::Log.first(key: 'version')
        expect(log).to_not be_nil
        expect(log.value.to_s).to eql '99'
      end
    end

    context 'if a version log does not exist' do
      it 'should create a new entry' do
        log = Models::Log.first(key: 'version')
        expect(log).to be_nil
        subject.current_version_number = '99'
        subject.refresh_version_log
        log = Models::Log.first(key: 'version')
        expect(log).to_not be_nil
        expect(log.value.to_s).to eql '99'
      end
    end
  end

  describe '#rebuild_cache' do
    it 'should warn the user the cache is being refreshed' do
      subject.rebuild_cache
      expect(subject).to have_received(:print_warning)
        .with('Refreshing the module cache...')
    end

    it 'should truncate the existing cache' do
      Models::Module.create(
        path: 'exploit/shell/test',
        name: 'test',
        type: 'exploit',
        class_name: 'Wpxf::Exploit::Test'
      )

      expect(Models::Module.first(name: 'test')).to_not be_nil
      subject.rebuild_cache
      expect(Models::Module.first(name: 'test')).to be_nil
    end

    it 'should create a {Models::Module} for each class in the Wpxf::Exploit namespace' do
      modules = Wpxf::Exploit.constants.select do |c|
        Wpxf::Exploit.const_get(c).is_a? Class
      end

      subject.rebuild_cache
      exploit_count = Models::Module.where(type: 'exploit').count
      expect(exploit_count).to eql modules.count
    end

    it 'should create a {Models::Module} for each class in the Wpxf::Exploit namespace' do
      modules = Wpxf::Auxiliary.constants.select do |c|
        Wpxf::Auxiliary.const_get(c).is_a? Class
      end

      subject.rebuild_cache
      exploit_count = Models::Module.where(type: 'auxiliary').count
      expect(exploit_count).to eql modules.count
    end

    it 'should update the version log' do
      allow(subject).to receive(:refresh_version_log)
      subject.rebuild_cache
      expect(subject).to have_received(:refresh_version_log).exactly(1).times
    end

    it 'should reset the context stack' do
      subject.rebuild_cache
      expect(subject).to have_received(:reset_context_stack)
    end
  end
end
