# frozen_string_literal: true

require_relative '../../spec_helper'

describe Models::Workspace, type: :model do
  it { is_expected.to have_one_to_many :credentials }
  it { is_expected.to validate_presence :name }
  it { is_expected.to validate_max_length 50, :name }
end
