# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::Models::Module, type: :model do
  it { is_expected.to validate_presence :path }
  it { is_expected.to validate_presence :name }
  it { is_expected.to validate_presence :type }
  it { is_expected.to validate_presence :class_name }

  it { is_expected.to validate_unique :path }
  it { is_expected.to validate_unique :class_name }

  it { is_expected.to validate_max_length 255, :path }
  it { is_expected.to validate_max_length 255, :name }
  it { is_expected.to validate_max_length 255, :class_name }

  it { is_expected.to validate_format(/^auxiliary|exploit$/, :type) }
end
