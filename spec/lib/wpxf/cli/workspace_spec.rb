# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/cli/workspace'
require 'wpxf/modules'

describe Wpxf::Cli::Workspace do
  let :subject do
    Class.new do
      include Wpxf::Cli::Workspace

      def initialize
        super
      end
    end.new
  end

  before(:each, 'setup mocks') do
    allow(subject).to receive(:print_bad)
    allow(subject).to receive(:print_good)
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:print_info)
    allow(subject).to receive(:context)

    Wpxf::Models::Workspace.insert(name: 'test_a')
    Wpxf::Models::Workspace.insert(name: 'test_b')
  end

  describe '#new' do
    it 'should initialise the current workspace' do
      workspace = subject.active_workspace
      expect(workspace).to be_a Wpxf::Models::Workspace
      expect(workspace.name).to eql 'default'
    end
  end

  describe '#active_workspace' do
    it 'should return the current `Models::Workspace`' do
      workspace = subject.active_workspace
      expect(workspace).to be_a Wpxf::Models::Workspace
      expect(workspace.name).to eql 'default'
    end
  end

  describe '#workspaces' do
    it 'should return an array of available workspaces' do
      expect(subject.workspaces.length).to eq 3
      expect(subject.workspaces[0].name).to eql 'default'
      expect(subject.workspaces[1].name).to eql 'test_a'
      expect(subject.workspaces[2].name).to eql 'test_b'
    end
  end

  describe '#list_workspaces' do
    it 'should list the available workspaces' do
      subject.list_workspaces
      expect(subject).to have_received(:print_info).exactly(3).times
    end

    it 'should mark the active workspace' do
      subject.list_workspaces
      expect(subject).to have_received(:print_info)
        .with("default #{'(active)'.green}")
    end

    it 'should list the names of workspaces' do
      subject.list_workspaces
      expect(subject).to have_received(:print_info).with('test_a')
    end
  end

  describe '#switch_workspace' do
    it 'should switch to the workspace with the matching `name`' do
      expect(subject.active_workspace.name).to eql 'default'
      subject.switch_workspace 'test_a'
      expect(subject.active_workspace.name).to eql 'test_a'
    end

    it 'should display a notification' do
      subject.switch_workspace 'test_a'
      expect(subject).to have_received(:print_good)
        .with('Switched to workspace: test_a')
    end

    context 'if `name` is not a valid workspace' do
      it 'should display an error' do
        subject.switch_workspace 'foo'
        expect(subject).to have_received(:print_bad)
          .with('foo is not a valid workspace')
      end

      it 'should not change the current workspace' do
        expect(subject.active_workspace.name).to eql 'default'
        subject.switch_workspace 'foo'
        expect(subject.active_workspace.name).to eql 'default'
      end
    end

    context 'if a module is loaded in the current context' do
      it 'should update the `active_workspace` of the module' do
        mod = Wpxf::Exploit::AdminShellUpload.new
        context_double = double('context')
        allow(context_double).to receive(:module).and_return(mod)
        allow(subject).to receive(:context).and_return(context_double)

        subject.switch_workspace 'test_a'
        expect(mod.active_workspace.name).to eql 'test_a'
      end
    end
  end

  describe '#delete_workspace' do
    context 'if `workspace` is `default`' do
      it 'should warn the user they cannot delete the default workspace' do
        subject.delete_workspace 'default'
        expect(subject).to have_received(:print_warning)
          .with('You cannot delete the default workspace')
      end
    end

    context 'if `workspace` is not `default`' do
      context 'if `workspace` is the current workspace' do
        it 'should switch to the default workspace' do
          subject.switch_workspace 'test_a'
          expect(subject.active_workspace.name).to eql 'test_a'
          subject.delete_workspace 'test_a'
          expect(subject.active_workspace.name).to eql 'default'
        end
      end

      it 'should destroy `workspace`' do
        subject.delete_workspace 'test_a'
        expect(Wpxf::Models::Workspace.where(name: 'test_a').count).to eql 0
      end

      context 'if a module is loaded in the current context' do
        it 'should update the `active_workspace` of the module' do
          mod = Wpxf::Exploit::AdminShellUpload.new
          context_double = double('context')
          allow(context_double).to receive(:module).and_return(mod)
          allow(subject).to receive(:context).and_return(context_double)

          subject.switch_workspace 'test_a'
          expect(mod.active_workspace.name).to eql 'test_a'

          subject.delete_workspace 'test_a'
          expect(mod.active_workspace.name).to eql 'default'
        end
      end
    end
  end

  describe '#workspace' do
    context 'if no arguments are specified' do
      it 'should list the workspaces' do
        allow(subject).to receive(:list_workspaces)
        subject.workspace
        expect(subject).to have_received(:list_workspaces)
      end
    end

    context 'if `-a` is the first arg' do
      it 'should invoke `add_workspace`' do
        allow(subject).to receive(:add_workspace)
        subject.workspace('-a', 'foo')
        expect(subject).to have_received(:add_workspace).with('foo')
      end
    end

    context 'if `-d` is the first arg' do
      it 'should invoke `delete_workspace`' do
        allow(subject).to receive(:delete_workspace)
        subject.workspace('-d', 'foo')
        expect(subject).to have_received(:delete_workspace).with('foo')
      end
    end

    context 'if the first arg is not a reserved option' do
      it 'should invoke `switch_workspace`' do
        allow(subject).to receive(:switch_workspace)
        subject.workspace('foo')
        expect(subject).to have_received(:switch_workspace).with('foo')
      end
    end
  end

  describe '#add_workspace' do
    context 'if `name` already exists' do
      it 'should warn the user' do
        subject.add_workspace('default')
        expect(subject).to have_received(:print_warning)
          .with('default already exists')
      end
    end

    context 'if `name` is unique' do
      it 'should create a new workspace' do
        subject.add_workspace('foo')
        count = Wpxf::Models::Workspace.where(name: 'foo').count
        expect(count).to eql 1
      end

      it 'should notify the user' do
        subject.add_workspace('foo')
        expect(subject).to have_received(:print_good)
          .with('Added workspace: foo')
      end
    end

    context 'if an invalid `name`is specified' do
      it 'should warn the user' do
        msg = 'Workspace names may only contain 1-50 alphanumeric characters and underscores'
        subject.add_workspace('foo-bar')
        expect(subject).to have_received(:print_warning).with(msg)
      end
    end
  end
end
