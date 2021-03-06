# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'wpxf/cli/loot'

describe Wpxf::Cli::Loot do
  let :subject do
    Class.new do
      include Wpxf::Cli::Loot
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

    Wpxf::Models::LootItem.create(
      host: '127.0.0.1',
      port: 80,
      path: 'test1',
      notes: 'notes1',
      type: 'file',
      workspace: subject.active_workspace
    )

    Wpxf::Models::LootItem.create(
      host: '127.0.0.1',
      port: 443,
      path: 'test2',
      notes: 'notes2',
      type: 'file',
      workspace: subject.active_workspace
    )
  end

  describe '#loot' do
    context 'if called with no arguments' do
      it 'should print a table of loot items' do
        id1 = Wpxf::Models::LootItem.first(port: 80).id
        id2 = Wpxf::Models::LootItem.first(port: 443).id

        expected = [
          { id: 'ID', host: 'Host', filename: 'Filename', notes: 'Notes', type: 'Type' },
          { id: id1, host: '127.0.0.1:80', filename: 'test1', notes: 'notes1', type: 'file' },
          { id: id2, host: '127.0.0.1:443', filename: 'test2', notes: 'notes2', type: 'file' }
        ]

        subject.loot
        expect(subject).to have_received(:print_table)
          .with(expected)
          .exactly(1).times
      end
    end

    context 'if called with the `-d` option' do
      it 'should validate that the specified ID exists in the workspace' do
        subject.loot '-d', '-999'
        expect(subject).to have_received(:print_bad)
          .with('Could not find loot item -999 in the current workspace')
          .exactly(1).times
      end

      it 'should destroy the specified loot item' do
        id2 = Wpxf::Models::LootItem.first(port: 443).id
        subject.loot '-d', id2
        expect(subject).to have_received(:print_good)
          .with("Deleted item #{id2}")
          .exactly(1).times

        count = Wpxf::Models::LootItem.where(port: 443).count
        expect(count).to eql 0
      end
    end

    context 'if called with the `-p` option' do
      it 'should validate that the specified ID exists in the workspace' do
        subject.loot '-p', '-999'
        expect(subject).to have_received(:print_bad)
          .with('Could not find loot item -999 in the current workspace')
          .exactly(1).times
      end

      it 'should print the content of the loot item to screen' do
        item = Wpxf::Models::LootItem.first(port: 443)
        allow(File).to receive(:read).and_return('dummy file contents')
        subject.loot '-p', item.id

        expect(File).to have_received(:read)
          .with(item.path)
          .exactly(1).times

        expect(subject).to have_received(:puts)
          .with('dummy file contents')
          .exactly(1).times
      end
    end
  end
end
