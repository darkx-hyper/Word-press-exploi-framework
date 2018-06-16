# frozen_string_literal: true

require_relative '../../spec_helper'
require 'cli/console'

describe Cli::Console do
  let(:subject) { Cli::Console.new }

  before :each, 'setup spies' do
    allow(subject).to receive(:print_warning)
    allow(subject).to receive(:rebuild_cache)
    allow(subject).to receive(:puts)
  end

  describe '#start' do
    before :each, 'setup mocks' do
      allow(subject).to receive(:prompt_for_input).and_return('exit')
      allow(subject).to receive(:check_cache)
    end

    it 'should check the module cache' do
      subject.start
      expect(subject).to have_received(:check_cache).exactly(1).times
    end
  end

  describe '#check_cache' do
    context 'if the module cache is not valid' do
      before(:each) do
        allow(subject).to receive(:cache_valid?).and_return(false)
      end

      it 'should refresh the module cache' do
        subject.check_cache
        expect(subject).to have_received(:rebuild_cache).exactly(1).times
      end
    end

    context 'if the module cache is valid' do
      before(:each) do
        allow(subject).to receive(:cache_valid?).and_return(true)
      end

      it 'should not refresh the cache' do
        subject.check_cache
        expect(subject).to have_received(:rebuild_cache).exactly(0).times
      end
    end
  end
end
