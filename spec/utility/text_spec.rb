# frozen_string_literal: true

require_relative '../spec_helper'

describe Wpxf::Utility::Text do
  describe '.alpha_ranges' do
    it 'returns an array containing the a-z range when using :lower' do
      expect(Wpxf::Utility::Text.alpha_ranges(:lower)).to eq [*'a'..'z']
    end

    it 'returns an array containing the A-Z range when using :upper' do
      expect(Wpxf::Utility::Text.alpha_ranges(:upper)).to eq [*'A'..'Z']
    end

    it 'returns an array containing the A-Z and a-z range when using :mixed' do
      range = [*'A'..'Z', *'a'..'z']
      expect(Wpxf::Utility::Text.alpha_ranges(:mixed)).to eq range
    end
  end

  describe '.rand_alpha' do
    it 'returns a string of the specified length' do
      val = Wpxf::Utility::Text.rand_alpha(10)
      expect(val.length).to eq 10
    end

    it 'returns a lower case string when :lower is specified as the casing' do
      val = Wpxf::Utility::Text.rand_alpha(10, :lower)
      expect(val).to match(/^[a-z]{10}$/)
    end

    it 'returns an upper case string when :upper is specified as the casing' do
      val = Wpxf::Utility::Text.rand_alpha(10, :upper)
      expect(val).to match(/^[A-Z]{10}$/)
    end

    it 'returns a mixed case string when :mixed is specified as the casing' do
      val = Wpxf::Utility::Text.rand_alpha(10, :mixed)
      expect(val).to match(/^[a-zA-Z]{10}$/)
    end

    it 'returns a mixed case string when no casing arg is specified' do
      val = Wpxf::Utility::Text.rand_alpha(10)
      expect(val).to match(/^[a-zA-Z]{10}$/)
    end
  end

  describe '.rand_alphanumeric' do
    it 'returns a string of the specified length' do
      val = Wpxf::Utility::Text.rand_alphanumeric(10)
      expect(val.length).to eq 10
    end

    it 'returns a lower case string when :lower is specified as the casing' do
      val = Wpxf::Utility::Text.rand_alphanumeric(10, :lower)
      expect(val).to match(/^[a-z0-9]{10}$/)
    end

    it 'returns an upper case string when :upper is specified as the casing' do
      val = Wpxf::Utility::Text.rand_alphanumeric(10, :upper)
      expect(val).to match(/^[A-Z0-9]{10}$/)
    end

    it 'returns a mixed case string when :mixed is specified as the casing' do
      val = Wpxf::Utility::Text.rand_alphanumeric(10, :mixed)
      expect(val).to match(/^[a-zA-Z0-9]{10}$/)
    end

    it 'returns a mixed case string when no casing arg is specified' do
      val = Wpxf::Utility::Text.rand_alphanumeric(10)
      expect(val).to match(/^[a-zA-Z0-9]{10}$/)
    end
  end

  describe '.rand_numeric' do
    it 'returns a string of the specified length' do
      val = Wpxf::Utility::Text.rand_numeric(10)
      expect(val.length).to eq 10
    end

    it 'returns a numeric string' do
      val = Wpxf::Utility::Text.rand_numeric(10)
      expect(val).to match(/^[0-9]{10}$/)
    end

    context 'when allow_leading_zero is set to false' do
      it 'returns a value that does not start with zero' do
        1000.times do
          val = Wpxf::Utility::Text.rand_numeric(3, false)
          expect(val[0]).to_not eq '0'
        end
      end
    end
  end

  describe '.md5' do
    it 'returns a hexadecimal representation of the md5 digest' do
      hash = Wpxf::Utility::Text.md5('test')
      expect(hash).to match(/^[a-f0-9]{32}$/i)
    end

    it 'returns an md5 hash' do
      hash = Wpxf::Utility::Text.md5('test')
      expect(hash).to eq '098f6bcd4621d373cade4e832627b4f6'
    end
  end

  describe '.rand_email' do
    it 'returns an address for a .com domain' do
      email = Wpxf::Utility::Text.rand_email
      expect(email).to match(/^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.com$/)
    end
  end
end
