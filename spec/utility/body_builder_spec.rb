require_relative '../spec_helper'

describe Wpxf::Utility::BodyBuilder do
  let(:subject) { Wpxf::Utility::BodyBuilder.new }

  before :each do
    allow(File).to receive(:open).with('stubbed_file', 'r')
      .and_return(:file_object)

    allow(subject).to receive(:create_tmp_file_from_string)
      .and_return('stubbed_file')
  end

  describe '#add_field' do
    it 'adds a key-value pair to the field list' do
      expect(subject.add_field('foo', 'bar'))
        .to include(type: :normal, value: 'bar')
    end
  end

  describe '#add_file' do
    it 'adds a file to the field list' do
      expect(subject.add_file('foo', 'bar.txt'))
        .to include(type: :file, path: 'bar.txt')

      expect(subject.add_file('bar', 'foo.txt', 'foobar.txt'))
        .to include(type: :file, path: 'foo.txt', remote_name: 'foobar.txt')
    end
  end

  describe '#add_file_from_string' do
    it 'adds a string to be used as a file field' do
      expect(subject.add_file_from_string('foo', 'bar', 'foobar.txt'))
        .to include(type: :mem_file, value: 'bar', remote_name: 'foobar.txt')
    end
  end

  describe '#create' do
    it 'creates a hash that can be used as a body when making HTTP requests.' do
      body = nil
      subject.add_field('normal', 'field')
      subject.add_file('file', 'stubbed_file')
      subject.add_file_from_string('fakefile', 'contents', 'remote.txt')

      subject.create do |b|
        body = b
      end

      expect(body['normal']).to eq 'field'
      expect(body['file']).to eq :file_object
      expect(body['fakefile']).to eq :file_object
    end
  end
end
