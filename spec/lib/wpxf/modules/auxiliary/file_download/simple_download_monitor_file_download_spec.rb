# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::SimpleDownloadMonitorFileDownload do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
    allow(subject).to receive(:emit_warning)
  end

  it 'should return a {Wpxf::Module}' do
    expect(subject).to be_a Wpxf::Module
  end

  it 'should check the plugin < 3.2.9' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('simple-download-monitor', '3.2.9')
      .exactly(1).times
  end

  it 'should not register the remote file option' do
    expect(subject.register_remote_file_option?).to be false
  end

  it 'should not require authentication' do
    expect(subject.requires_authentication).to be false
  end

  it 'should configure the downloader url' do
    expect(subject.downloader_url).to eql subject.wordpress_url_admin_ajax
  end

  it 'should configure the request params' do
    subject.set_option_value('post_id', 10)
    expect(subject.download_request_params).to eql(
      'action' => 'sdm_init_time_tasks',
      'smd_process_download' => '1',
      'download_id' => '10'
    )
  end

  it 'should GET the download request' do
    expect(subject.download_request_method).to eql :get
  end

  context 'if the download does not appear to be valid' do
    let(:content) { 'This download item (99) does not have any download link' }

    it 'should emit a warning' do
      subject.validate_content(content)
      expect(subject).to have_received(:emit_warning)
        .with('The file you requested appears to be invalid')
        .exactly(1).times
    end

    it 'should not fail validation' do
      res = subject.validate_content(content)
      expect(res).to be true
    end
  end
end
