# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/cli/context'

describe Wpxf::Cli::Context do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    Wpxf::Models::Module.create(
      path: 'exploit/shell/admin_shell_upload',
      type: 'exploit',
      name: 'Admin Shell Upload',
      class_name: 'Wpxf::Exploit::AdminShellUpload'
    )
  end

  describe '#verbose?' do
    context 'if a module is loaded' do
      it 'should return the value of the `verbose` option' do
        mod = subject.load_module('exploit/shell/admin_shell_upload')
        expect(subject.verbose?).to be false

        mod.set_option_value('verbose', true)
        expect(subject.verbose?).to be true
      end
    end

    context 'if a module is not loaded' do
      it 'should return false' do
        expect(subject.verbose?).to be false
      end
    end
  end

  describe '#load_module' do
    it 'should load the specified module into #module' do
      expect(subject.module).to be_nil
      subject.load_module('exploit/shell/admin_shell_upload')
      expect(subject.module).to be_a Wpxf::Exploit::AdminShellUpload
    end

    it 'should update #module_path' do
      expect(subject.module_path).to be_nil
      subject.load_module('exploit/shell/admin_shell_upload')
      expect(subject.module_path).to eql('exploit/shell/admin_shell_upload')
    end

    it 'should return the module' do
      res = subject.load_module('exploit/shell/admin_shell_upload')
      expect(res).to be_a Wpxf::Exploit::AdminShellUpload
    end
  end

  describe '#reload' do
    it 'should return the module' do
      subject.load_module('exploit/shell/admin_shell_upload')
      res = subject.reload
      expect(res).to be_a Wpxf::Exploit::AdminShellUpload
    end

    it 'should reload the source file of the current module' do
      allow(subject).to receive(:load)

      subject.load_module 'exploit/shell/admin_shell_upload'
      expect(subject).to_not have_received(:load)

      subject.reload
      expect(subject).to have_received(:load)
        .with('wpxf/modules/exploit/shell/admin_shell_upload.rb')
        .exactly(1).times
    end

    it 'should re-initialise the current module' do
      initial = subject.load_module('exploit/shell/admin_shell_upload')
      res = subject.reload
      expect(res.object_id).to_not eql initial.object_id
    end
  end

  describe '#load_payload' do
    it 'should set #module.payload to a new instance of the specified payload' do
      subject.load_module 'exploit/shell/admin_shell_upload'
      expect(subject.module.payload).to be_nil
      subject.load_payload 'reverse_tcp'
      expect(subject.module.payload).to be_a Wpxf::Payloads::ReverseTcp
    end

    it 'should run #module.payload.check' do
      payload = double('payload')
      allow(payload).to receive(:check)
      allow(Wpxf::Payloads).to receive(:load_payload).and_return(payload)

      subject.load_module 'exploit/shell/admin_shell_upload'
      subject.load_payload 'reverse_tcp'
      expect(payload).to have_received(:check)
        .with(subject.module)
        .exactly(1).times
    end

    it 'should return the payload' do
      subject.load_module 'exploit/shell/admin_shell_upload'
      res = subject.load_payload 'reverse_tcp'
      expect(res).to be_a Wpxf::Payloads::ReverseTcp
    end
  end
end
