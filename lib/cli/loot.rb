# frozen_string_literal: true

module Cli
  # A mixin to provide functions to interact with loot stored in the database.
  module Loot
    def creds
      rows = []
      rows.push(
        'host'     => 'Host',
        'username' => 'Username',
        'password' => 'Password',
        'type'     => 'Type'
      )

      Models::Credential.where(workspace: active_workspace).each do |cred|
        rows.push(
          'host'     => "#{cred.host}:#{cred.port}",
          'username' => cred.username,
          'password' => cred.password,
          'type'     => cred.type
        )
      end

      print_table rows
    end
  end
end
