# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::Db::Credentials do
  let(:subject) { (Class.new { include Wpxf::Db::Credentials }).new }

  before(:each) do
    workspace = Wpxf::Models::Workspace.create(name: 'test')

    allow(subject).to receive(:target_host).and_return('example.com')
    allow(subject).to receive(:target_port).and_return(80)
    allow(subject).to receive(:active_workspace).and_return(workspace)
  end

  describe '#store_credential' do
    it 'should insert a new record into the `credentials` table' do
      expect(Wpxf::Models::Credential.count).to eql 0
      subject.store_credentials 'foo', 'bar'
      expect(Wpxf::Models::Credential.count).to eql 1
    end

    it 'should transparently set the host information' do
      subject.store_credentials 'foo', 'bar'
      credential = Wpxf::Models::Credential.first
      expect(credential.host).to eql 'example.com'
      expect(credential.port).to eql 80
    end

    it 'should transparently set the workspace information' do
      subject.store_credentials 'foo', 'bar'
      credential = Wpxf::Models::Credential.first
      expect(credential.workspace.name).to eql 'test'
    end

    it 'should set the credential type to `plain` if not specified' do
      subject.store_credentials 'foo', 'bar'
      credential = Wpxf::Models::Credential.first
      expect(credential.type).to eql 'plain'
    end

    it 'should store `nil` passwords as an empty string' do
      subject.store_credentials 'foo', nil
      credential = Wpxf::Models::Credential.first
      expect(credential.password).to_not be_nil
      expect(credential.password).to eql ''
    end

    context 'if a record with the same host + username + type already exists' do
      context 'and the record is in the same workspace' do
        context 'and has no password' do
          it 'should overwrite the previous credential' do
            subject.store_credentials 'foo', '', 'test'
            subject.store_credentials 'foo', 'bar', 'test'
            expect(Wpxf::Models::Credential.count).to eql 1

            credential = Wpxf::Models::Credential.first
            expect(credential.password).to eql 'bar'
          end
        end

        context 'and has a password' do
          context 'if the password is the same' do
            it 'should overwrite the previous credential' do
              subject.store_credentials 'foo', 'bar', 'test'
              subject.store_credentials 'foo', 'bar', 'test'
              expect(Wpxf::Models::Credential.count).to eql 1
            end
          end

          context 'if the new password is blank' do
            it 'should not overwrite the existing pasword' do
              subject.store_credentials 'foo', 'bar', 'test'
              subject.store_credentials 'foo', '', 'test'
              expect(Wpxf::Models::Credential.count).to eql 1
              expect(Wpxf::Models::Credential.first.password).to eql 'bar'
            end
          end

          context 'if the password is different' do
            it 'should add a new entry' do
              Wpxf::Models::Credential.create(
                host: subject.target_host,
                port: subject.target_port,
                username: 'foo',
                password: 'bar',
                type: 'plain',
                workspace: Wpxf::Models::Workspace.first(name: 'default')
              )

              expect(Wpxf::Models::Credential.count).to eql 1
              subject.store_credentials 'foo', 'foo'
              expect(Wpxf::Models::Credential.count).to eql 2
            end
          end
        end
      end

      context 'and is not in the same workspace' do
        it 'should add a new entry' do
          Wpxf::Models::Credential.create(
            host: subject.target_host,
            port: subject.target_port,
            username: 'foo',
            password: 'bar',
            type: 'plain',
            workspace: Wpxf::Models::Workspace.first(name: 'default')
          )

          expect(Wpxf::Models::Credential.count).to eql 1
          subject.store_credentials 'foo', 'foo'
          expect(Wpxf::Models::Credential.count).to eql 2
        end
      end
    end
  end
end
