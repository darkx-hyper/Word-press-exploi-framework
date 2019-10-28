# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::Versioning::BrowserVersions do
  let(:subject) do
    (Class.new { include Wpxf::Versioning::BrowserVersions }).new
  end

  describe '#random_ie_version' do
    it 'returns a String' do
      expect(subject.random_ie_version).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^[7-9]\.0$/
      expect(subject.random_ie_version).to match pattern
    end
  end

  describe '#random_trident_version' do
    it 'returns a String' do
      expect(subject.random_trident_version).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^[3-5]\.[0-1]$/
      expect(subject.random_trident_version).to match pattern
    end
  end

  describe '#random_chrome_version' do
    it 'returns a String' do
      expect(subject.random_chrome_version).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^1[3-5]\.0\.8[0-9]{2}\.0$/
      expect(subject.random_chrome_version).to match pattern
    end
  end

  describe '#random_presto_version' do
    it 'returns a String' do
      expect(subject.random_presto_version).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^2\.9\.1([6-8][0-9]|90)$/
      expect(subject.random_presto_version).to match pattern
    end
  end

  describe '#random_presto_version2' do
    it 'returns a String' do
      expect(subject.random_presto_version2).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^1[0-2]\.00$/
      expect(subject.random_presto_version2).to match pattern
    end
  end

  describe '#random_safari_build_number' do
    it 'returns a String' do
      expect(subject.random_safari_build_number).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^53[1-5]\.([1-9]|[1-4][0-9]|50)\.[1-7]$/
      expect(subject.random_safari_build_number).to match pattern
    end
  end

  describe '#random_safari_version' do
    it 'returns a String' do
      expect(subject.random_safari_version).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^[4-5]\.(0\.[1-5]|[0-1])$/
      expect(subject.random_safari_version).to match pattern
    end
  end

  describe '#random_chrome_build_number' do
    it 'returns a String' do
      expect(subject.random_chrome_build_number).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^53[1-6]\.[0-2]$/
      expect(subject.random_chrome_build_number).to match pattern
    end
  end

  describe '#random_opera_version' do
    it 'returns a String' do
      expect(subject.random_opera_version).to be_a String
    end

    it 'returns a string in the correct format' do
      pattern = /^[8-9]\.([1-8][0-9]|9[0-8|99])$/
      expect(subject.random_opera_version).to match pattern
    end
  end
end