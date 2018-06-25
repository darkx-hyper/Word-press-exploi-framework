# frozen_string_literal: true

require_relative '../../spec_helper'
require 'cli/loot'

describe Cli::Loot do
  let :subject do
    Class.new do
      include Cli::Loot
    end.new
  end

  before :each, 'setup subject and samples' do
    allow(subject).to receive(:active_workspace).and_return(Models::Workspace.first)
    allow(subject).to receive(:print_table)

    Models::Credential.create(
      host: '127.0.0.1',
      port: 80,
      username: 'test1',
      password: 'test1',
      type: 'plain',
      workspace: subject.active_workspace
    )

    Models::Credential.create(
      host: '127.0.0.1',
      port: 443,
      username: 'test2',
      password: 'test2',
      type: 'plain',
      workspace: subject.active_workspace
    )
  end

  describe '#creds' do
    it 'should print a table of credentials' do
      expected = [
        { 'host' => 'Host', 'username' => 'Username', 'password' => 'Password', 'type' => 'Type' },
        { 'host' => '127.0.0.1:80', 'username' => 'test1', 'password' => 'test1', 'type' => 'plain' },
        { 'host' => '127.0.0.1:443', 'username' => 'test2', 'password' => 'test2', 'type' => 'plain' }
      ]

      subject.creds
      expect(subject).to have_received(:print_table)
        .with(expected)
        .exactly(1).times
    end
  end
end
