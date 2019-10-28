# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::LoadScriptsDos do
  let(:subject) { described_class.new }
  let(:wordpress_and_online?) { true }

  before :each, 'setup subject' do
    allow(subject).to receive(:wordpress_and_online?).and_return(wordpress_and_online?)
    allow(subject).to receive(:queue_request).and_call_original
    allow(subject).to receive(:execute_queued_requests).and_call_original
    allow(subject).to receive(:emit_error)
    allow(subject).to receive(:emit_warning)
    allow(subject).to receive(:emit_success)

    subject.set_option_value('host', '127.0.0.1')
    subject.set_option_value('max_requests', 50)
    subject.set_option_value('check_wordpress_and_online', false)
  end

  context 'if the target is running any version of WordPress' do
    let(:wordpress_and_online?) { true }

    it 'should consider it vulnerable' do
      expect(subject.check).to eql :vulnerable
    end
  end

  context 'if the target does not appear to be running WordPress' do
    let(:wordpress_and_online?) { false }

    it 'should consider the vulnerability status to be unknown' do
      expect(subject.check).to eql :unknown
    end
  end

  it 'should queue and execute the specified numbers of requests' do
    subject.run
    expect(subject).to have_received(:queue_request)
      .exactly(50).times

    expect(subject).to have_received(:execute_queued_requests)
    expect(subject.complete_requests).to eql 50
  end

  it 'should emit a process update every 10 requests that are executed' do
    subject.run
    expect(subject).to have_received(:emit_warning).exactly(5).times
  end

  context 'if the target appears to be online after executing the requests' do
    let(:wordpress_and_online?) { true }

    it 'should emit an error' do
      subject.run
      expect(subject).to have_received(:emit_error)
        .with("FAILED: #{subject.full_uri} appears to still be online")
        .exactly(1).times
    end

    it 'should fail the module execution' do
      expect(subject.run).to be false
    end
  end

  context 'if the target appears to be offline after executing the requests' do
    let(:wordpress_and_online?) { false }

    it 'should emit a success message' do
      subject.run
      expect(subject).to have_received(:emit_success)
        .with("#{subject.full_uri} appears to be down")
        .exactly(1).times
    end

    it 'should successfully complete the module execution' do
      expect(subject.run).to be true
    end
  end
end