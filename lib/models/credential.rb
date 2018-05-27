# frozen_string_literal: true

module Models
  # A set of credentials for a specific target.
  class Credential < Sequel::Model
    plugin :validation_helpers

    many_to_one :workspace

    def validate
      super

      validates_presence :host
      validates_presence :port

      validates_numeric :port
      validates_type String, :username, allow_nil: true
      validates_type String, :password, allow_nil: true

      validates_max_length 250, :username
      validates_max_length 250, :password
      validates_max_length 250, :host
    end
  end
end
