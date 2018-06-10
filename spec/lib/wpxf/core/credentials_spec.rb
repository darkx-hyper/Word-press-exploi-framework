# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::Credentials do
  let(:subject) { (Class.new { include Wpxf::Credentials }).new }

  before(:each) do
    workspace = Models::Workspace.create(name: 'test')

    allow(subject).to receive(:target_host).and_return('example.com')
    allow(subject).to receive(:target_port).and_return(80)
    allow(subject).to receive(:active_workspace).and_return(workspace)
  end

  describe '#store_credential' do
    it 'should insert a new record into the `credentials` table' do
      expect(Models::Credential.count).to eql 0
      subject.store_credentials 'foo', 'bar'
      expect(Models::Credential.count).to eql 1
    end

    it 'should transparently set the host information' do
      subject.store_credentials 'foo', 'bar'
      credential = Models::Credential.first
      expect(credential.host).to eql 'example.com'
      expect(credential.port).to eql 80
    end

    it 'should transparently set the workspace information' do
      subject.store_credentials 'foo', 'bar'
      credential = Models::Credential.first
      expect(credential.workspace.name).to eql 'test'
    end

    it 'should set the credential type to `plain` if not specified' do
      subject.store_credentials 'foo', 'bar'
      credential = Models::Credential.first
      expect(credential.type).to eql 'plain'
    end

    context 'if a record with the same host + username already exists' do
      context 'and the record is in the same workspace' do
        it 'should overwrite the previous credential' do
          subject.store_credentials 'foo', 'bar'
          subject.store_credentials 'foo', 'foo'
          expect(Models::Credential.count).to eql 1

          credential = Models::Credential.first
          expect(credential.password).to eql 'foo'
        end
      end

      context 'and is not in the same workspace' do
        it 'should add a new entry' do
          Models::Credential.create(
            host: subject.target_host,
            port: subject.target_port,
            username: 'foo',
            password: 'bar',
            type: 'plain',
            workspace: Models::Workspace.first(name: 'default')
          )

          expect(Models::Credential.count).to eql 1
          subject.store_credentials 'foo', 'foo'
          expect(Models::Credential.count).to eql 2
        end
      end
    end
  end
end
