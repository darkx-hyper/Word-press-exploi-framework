# frozen_string_literal: true

# Provides functionality for storing and updating credentials.
module Wpxf::Db::Credentials
  # Store a new set of credentials in the database.
  # @param username [String] the username.
  # @param password [String] the password.
  # @param type [String] the type of string stored in the password field.
  # @return [Models::Credential] the newly created {Models::Credential}.
  def store_credentials(username, password = '', type = 'plain')
    credential = Wpxf::Models::Credential.first(
      host: target_host,
      port: target_port,
      username: username,
      type: type,
      workspace: active_workspace
    )

    credential = Wpxf::Models::Credential.new if credential.nil?
    credential.host = target_host
    credential.port = target_port
    credential.username = username
    credential.password = _determine_password_to_store(credential, password)
    credential.type = type
    credential.workspace = active_workspace

    credential.save
  end

  private

  def _determine_password_to_store(model, new_password)
    new_password = '' if new_password.nil?
    return model.password if new_password == '' && !model.password.nil?
    new_password
  end
end
