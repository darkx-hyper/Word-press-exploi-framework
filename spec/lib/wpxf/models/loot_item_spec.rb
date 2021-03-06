# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::Models::LootItem, type: :model do
  it { is_expected.to have_many_to_one :workspace }
  it { is_expected.to validate_presence :host }
  it { is_expected.to validate_presence :port }
  it { is_expected.to validate_presence :path }
  it { is_expected.to validate_max_length 250, :host }
  it { is_expected.to validate_max_length 50, :type }
  it { is_expected.to validate_max_length 100, :notes }
  it { is_expected.to validate_numeric :port }
  it { is_expected.to validate_max_length 500, :path }

  describe '#destroy' do
    before :each, 'create loot item' do
      Wpxf::Models::LootItem.create(
        host: 'localhost',
        port: 80,
        path: 'test',
        type: 'file',
        workspace: Wpxf::Models::Workspace.first
      )
    end

    context 'if the file no longer exists' do
      it 'should not attempt to remove it' do
        allow(File).to receive(:exist?).and_return(false)
        allow(FileUtils).to receive(:rm)

        Wpxf::Models::LootItem.first.destroy
        expect(FileUtils).to_not have_received(:rm)
        expect(Wpxf::Models::LootItem.count).to eql 0
      end
    end

    context 'if the file still exists' do
      it 'should remove it' do
        allow(File).to receive(:exist?).and_return(true)
        allow(FileUtils).to receive(:rm)

        Wpxf::Models::LootItem.first.destroy
        expect(FileUtils).to have_received(:rm)
          .with('test')
          .exactly(1).times

        expect(Wpxf::Models::LootItem.count).to eql 0
      end

      context 'if an error occurs removing the file' do
        it 'should raise an error' do
          allow(File).to receive(:exist?).and_return(true)
          allow(FileUtils).to receive(:rm).and_raise('mock error')

          expect { Wpxf::Models::LootItem.first.destroy }.to raise_error('mock error')
          expect(Wpxf::Models::LootItem.count).to eql 1
        end
      end
    end
  end
end
