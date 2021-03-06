# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/cli/creds'

describe Wpxf::Cli::Creds do
  let :subject do
    Class.new do
      include Wpxf::Cli::Creds
    end.new
  end

  before :each, 'setup subject and samples' do
    allow(subject).to receive(:active_workspace).and_return(Wpxf::Models::Workspace.first)
    allow(subject).to receive(:print_table)
    allow(subject).to receive(:print_std)
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:puts)

    Wpxf::Models::Credential.create(
      host: '127.0.0.1',
      port: 80,
      username: 'test1',
      password: 'test1',
      type: 'plain',
      workspace: subject.active_workspace
    )

    Wpxf::Models::Credential.create(
      host: '127.0.0.1',
      port: 443,
      username: 'test2',
      password: 'test2',
      type: 'plain',
      workspace: subject.active_workspace
    )
  end

  describe '#creds' do
    context 'if called with no arguments' do
      it 'should print a table of credentials' do
        id1 = Wpxf::Models::Credential.first(port: 80).id
        id2 = Wpxf::Models::Credential.first(port: 443).id

        expected = [
          { id: 'ID', host: 'Host', username: 'Username', password: 'Password', type: 'Type' },
          { id: id1, host: '127.0.0.1:80', username: 'test1', password: 'test1', type: 'plain' },
          { id: id2, host: '127.0.0.1:443', username: 'test2', password: 'test2', type: 'plain' }
        ]

        subject.creds
        expect(subject).to have_received(:print_table)
          .with(expected)
          .exactly(1).times
      end
    end

    context 'if called with the `-d` option' do
      it 'should validate that the specified ID exists in the workspace' do
        subject.creds '-d', '-999'
        expect(subject).to have_received(:print_bad)
          .with('Could not find credential -999 in the current workspace')
          .exactly(1).times
      end

      it 'should destroy the specified credentials' do
        id = Wpxf::Models::Credential.first(port: 443).id
        subject.creds '-d', id
        expect(subject).to have_received(:print_good)
          .with("Deleted credential #{id}")
          .exactly(1).times

        count = Wpxf::Models::Credential.where(port: 443).count
        expect(count).to eql 0
      end
    end
  end
end
