# frozen_string_literal: true

module Models
  # A workspace with isolated loot and credentials.
  class Workspace < Sequel::Model
    plugin :validation_helpers

    one_to_many :credentials

    def validate
      super

      validates_presence :name
      validates_type String, :name
      validates_max_length 50, :name
    end
  end
end
