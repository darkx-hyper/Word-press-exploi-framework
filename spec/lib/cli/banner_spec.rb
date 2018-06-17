# frozen_string_literal: true

require_relative '../../spec_helper'
require 'cli/banner'

describe Cli::Banner do
  let(:subject) { described_class.new }

  before :each, 'setup mocks' do
    allow(subject).to receive(:puts)

    (1..5).each do |i|
      Models::Module.create(
        path: "test#{i}/",
        name: "Test #{i}",
        class_name: "Test#{i}",
        type: 'exploit'
      )
    end

    (6..8).each do |i|
      Models::Module.create(
        path: "test#{i}/",
        name: "Test #{i}",
        class_name: "Test#{i}",
        type: 'auxiliary'
      )
    end
  end

  describe '#new' do
    it 'should initialise #raw_content with the content of `data/banners/default.txt`' do
      base_path = File.expand_path(File.join(__dir__, '..', '..', '..'))
      banner_path = File.join(base_path, 'data', 'banners', 'default.txt')
      expected = File.read(banner_path)

      expect(subject.raw_content).to eql expected
    end
  end

  describe '#format_colour' do
    it 'should replace {WB} with the ANSI code for white bold text' do
      res = subject.format_colour('this is a {WB}test')
      expect(res).to eql "this is a \e[0m\e[97m\e[1mtest"
    end

    it 'should replace {WN} with the ANSI code for white normal text' do
      res = subject.format_colour('this is a {WN}test')
      expect(res).to eql "this is a \e[0m\e[97mtest"
    end

    it 'should replace {GN} with the ANSI code for green normal text' do
      res = subject.format_colour('this is a {GN}test')
      expect(res).to eql "this is a \e[0m\e[32mtest"
    end

    it 'should replace {LGN} with the ANSI code for light grey normal text' do
      res = subject.format_colour('this is a {LGN}test')
      expect(res).to eql "this is a \e[0m\e[37mtest"
    end

    it 'should replace {WB} with the ANSI code for yellow bold text' do
      res = subject.format_colour('this is a {YB}test')
      expect(res).to eql "this is a \e[0m\e[33m\e[1mtest"
    end
  end

  describe '#auxiliary_count' do
    it 'should return the number of auxiliary modules loaded' do
      expect(subject.auxiliary_count).to eql 3
    end
  end

  describe '#exploit_count' do
    it 'should return the number of exploit modules loaded' do
      expect(subject.exploit_count).to eql 5
    end
  end

  describe '#format_data' do
    it 'should replace {VERSION} with the current version of WPXF' do
      base_path = File.expand_path(File.join(__dir__, '..', '..', '..'))
      version_path = File.join(base_path, 'VERSION')
      expected = File.read(version_path).strip

      expect(subject.format_data('V:{VERSION}')).to eql "V:#{expected}"
    end

    it 'should replace {AUXILIARY_COUNT} with the number of auxiliary modules loaded' do
      res = subject.format_data('A:{AUXILIARY_COUNT}')
      expect(res).to eql 'A:3'
    end

    it 'should replace {EXPLOIT_COUNT} with the number of exploit modules loaded' do
      res = subject.format_data('A:{EXPLOIT_COUNT}')
      expect(res).to eql 'A:5'
    end

    it 'should replace {PAYLOAD_COUNT} with the number of exploit modules loaded' do
      payloads = Wpxf::Payloads.constants.select do |c|
        Wpxf::Payloads.const_get(c).is_a? Class
      end

      res = subject.format_data('A:{PAYLOAD_COUNT}')
      expect(res).to eql "A:#{payloads.size}"
    end
  end

  describe '#display' do
    it 'should print the fully formatted banner' do
      expected = subject.format_data(subject.raw_content)
      expected = subject.format_colour(expected)
      subject.display

      expect(subject).to have_received(:puts).with(expected)
    end
  end
end
