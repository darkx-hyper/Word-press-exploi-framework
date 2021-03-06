# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/cli/module_info'

describe Wpxf::Cli::ModuleInfo do
  let :subject do
    Class.new do
      include Wpxf::Cli::ModuleInfo

      def initialize
        super
      end

      def indent_cursor
        yield
      end

      attr_accessor :context
    end.new
  end

  let(:mod) { Wpxf::Module.new }
  let(:module_desc) { 'Desc' }
  let(:module_description_preformatted) { false }
  let(:module_references) { nil }

  before(:each, 'setup mocks') do
    allow(subject).to receive(:puts)
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:print_info)
    allow(subject).to receive(:print_std)
    allow(subject).to receive(:indent_without_wrap).and_return('indent_without_wrap')
    allow(subject).to receive(:remove_new_lines_and_wrap_text).and_return('remove_new_lines_and_wrap_text')

    mod.update_info(
      name: 'Test',
      desc: module_desc,
      desc_preformatted: module_description_preformatted,
      author: %w[author1 author2],
      date: '19 Jun 2018',
      references: module_references
    )

    subject.context = double('context')
    allow(subject.context).to receive(:module).and_return(mod)
    allow(subject.context).to receive(:module_path).and_return('mod/path')
  end

  describe '#print_author' do
    it 'should print a section header' do
      subject.print_author
      expect(subject).to have_received(:print_std)
        .with('Provided by:')
        .exactly(1).times
    end

    it 'should print the name of each author in the current module' do
      subject.print_author
      expect(subject).to have_received(:print_std).with('author1')
      expect(subject).to have_received(:print_std).with('author2')
    end

    it 'should indent the cursor before printing the authors' do
      allow(subject).to receive(:indent_cursor) do |&block|
        expect(subject).to_not have_received(:print_std).with('author1')
        expect(subject).to_not have_received(:print_std).with('author2')
        block.call
      end

      subject.print_author
      expect(subject).to have_received(:indent_cursor)
    end
  end

  describe '#formatted_module_description' do
    context 'if the module description is pre-formatted' do
      let(:module_description_preformatted) { true }

      it 'should return the indented description without automated wrapping' do
        res = subject.formatted_module_description
        expect(res).to eql 'indent_without_wrap'
      end
    end

    context 'if the module description is not pre-formatted' do
      let(:module_description_preformatted) { false }

      it 'should return the indented description with new lines removed and automated wrapping' do
        res = subject.formatted_module_description
        expect(res).to eql 'remove_new_lines_and_wrap_text'
      end
    end
  end

  describe '#print_description' do
    before :each, 'setup spies' do
      allow(subject).to receive(:formatted_module_description)
    end

    it 'should print a section header' do
      subject.print_description
      expect(subject).to have_received(:print_std)
        .with('Description:')
        .exactly(1).times
    end

    it 'should indent the cursor before printing a description' do
      allow(subject).to receive(:indent_cursor) do |&block|
        expect(subject).to_not have_received(:formatted_module_description)
        block.call
      end

      subject.print_description
      expect(subject).to have_received(:indent_cursor)
    end

    it 'should print the formatted module description' do
      subject.print_description
      expect(subject).to have_received(:formatted_module_description)
    end
  end

  describe '#print_module_summary' do
    it 'should print the module name' do
      subject.print_module_summary
      expect(subject).to have_received(:print_std)
        .with('       Name: Test').exactly(1).times
    end

    it 'should print the module path' do
      subject.print_module_summary
      expect(subject).to have_received(:print_std)
        .with('     Module: mod/path').exactly(1).times
    end

    it 'should print the date of disclosure' do
      subject.print_module_summary
      expect(subject).to have_received(:print_std)
        .with('  Disclosed: 2018-06-19').exactly(1).times
    end
  end

  describe '#print_references' do
    context 'if the module has no references' do
      it 'should print nothing' do
        subject.print_references
        expect(subject).to_not have_received(:print_std)
      end
    end

    context 'if the module has references' do
      let(:module_references) { [%w[CVE 1234], %w[WPVDB 321]] }

      it 'should print a section header' do
        subject.print_references
        expect(subject).to have_received(:print_std).with('References:').exactly(1).times
      end

      it 'should indent the cursor before printing any references' do
        allow(subject).to receive(:indent_cursor) do |&block|
          expect(subject).to_not have_received(:print_std)
            .with('http://www.cvedetails.com/cve/CVE-1234')

          expect(subject).to_not have_received(:print_std)
            .with('https://wpvulndb.com/vulnerabilities/321')

          block.call
        end

        subject.print_references
        expect(subject).to have_received(:indent_cursor)
      end

      it 'should print the inflated references' do
        subject.print_references
        expect(subject).to have_received(:print_std)
          .with('http://www.cvedetails.com/cve/CVE-1234')
          .exactly(1).times

        expect(subject).to have_received(:print_std)
          .with('https://wpvulndb.com/vulnerabilities/321')
          .exactly(1).times
      end
    end
  end

  describe '#info' do
    before :each, 'setup spies' do
      allow(subject).to receive(:print_module_summary)
      allow(subject).to receive(:print_author)
      allow(subject).to receive(:show_options)
      allow(subject).to receive(:print_description)
      allow(subject).to receive(:print_references)
    end

    context 'if a module is not loaded' do
      it 'should print nothing' do
        allow(subject).to receive(:module_loaded?).and_return(false)
        subject.info
        expect(subject).to_not have_received(:print_module_summary)
        expect(subject).to_not have_received(:print_author)
        expect(subject).to_not have_received(:show_options)
        expect(subject).to_not have_received(:print_description)
        expect(subject).to_not have_received(:print_references)
      end
    end

    context 'if a module is loaded' do
      before :each, 'setup mocks' do
        allow(subject).to receive(:module_loaded?).and_return(true)
      end

      it 'should print the module summary' do
        subject.info
        expect(subject).to have_received(:print_module_summary)
      end

      it 'should print the author(s)' do
        subject.info
        expect(subject).to have_received(:print_author)
      end

      it 'should print the options table' do
        subject.info
        expect(subject).to have_received(:show_options)
      end

      it 'should print the module description' do
        subject.info
        expect(subject).to have_received(:print_description)
      end

      it 'should print the module references' do
        subject.info
        expect(subject).to have_received(:print_references)
      end
    end
  end
end
