# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::Models::Credential, type: :model do
  it { is_expected.to have_many_to_one :workspace }
  it { is_expected.to validate_presence :host }
  it { is_expected.to validate_presence :port }
  it { is_expected.to validate_max_length 250, :username }
  it { is_expected.to validate_max_length 250, :password }
  it { is_expected.to validate_max_length 250, :host }
  it { is_expected.to validate_max_length 20, :type }
  it { is_expected.to validate_numeric :port }
end
