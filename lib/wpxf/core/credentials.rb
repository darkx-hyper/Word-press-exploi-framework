# frozen_string_literal: true

module Wpxf
  # Provides functionality for storing and updating credentials.
  module Credentials
    # Store a new set of credentials in the database.
    # @param username [String] the username.
    # @param password [String] the password.
    # @param type [String] the type of string stored in the password field.
    # @return [Models::Credential] the newly created {Models::Credential}.
    def store_credentials(username, password, type = 'plain')
      credential = Models::Credential.first(
        host: target_host,
        port: target_port,
        username: username,
        workspace: active_workspace
      )

      credential = Models::Credential.new if credential.nil?
      credential.host = target_host
      credential.port = target_port
      credential.username = username
      credential.password = password
      credential.type = type
      credential.workspace = active_workspace

      credential.save
    end
  end
end
