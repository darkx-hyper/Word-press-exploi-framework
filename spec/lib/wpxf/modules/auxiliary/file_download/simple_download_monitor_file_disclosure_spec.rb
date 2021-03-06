# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::SimpleDownloadMonitorFileDisclosure do
  let(:subject) { described_class.new }
  let(:downloaded_filename) { File.join(Dir.tmpdir, 'wpxf_unit_test') }
  let(:content_mock) do
    %(
      {
        "test": [
          { "post_id": 1, "post_title": "test1" },
          { "post_id": 2, "post_title": "test2" }
        ]
      }
    )
  end

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
    allow(subject).to receive(:emit_error)
    allow(subject).to receive(:emit_table)
    allow(subject).to receive(:downloaded_filename).and_return(downloaded_filename)
  end

  after :each, 'delete tmp files' do
    FileUtils.rm_f downloaded_filename
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
    expect(subject.download_request_params).to eql('action' => 'sdm_tiny_get_post_ids')
  end

  it 'should GET the download request' do
    expect(subject.download_request_method).to eql :get
  end

  context 'if the response is valid JSON' do
    it 'should save the export as a CSV' do
      expect(subject.file_extension).to eql '.csv'
      subject.validate_content(content_mock)
      csv = CSV.parse(downloaded_filename)
      expect(csv).to_not be_nil
    end

    it 'should emit the post ids and titles as a table' do
      expected_table = [
        { post_id: 'Post ID', title: 'Title' },
        { post_id: 1, title: 'test1' },
        { post_id: 2, title: 'test2' }
      ]

      subject.validate_content(content_mock)
      expect(subject).to have_received(:emit_table)
        .with(expected_table)
        .exactly(1).times
    end
  end

  context 'if the response is not valid JSON' do
    it 'should fail the validation process' do
      res = subject.validate_content('invalid json')
      expect(res).to be false
    end

    it 'should emit an error' do
      subject.validate_content('invalid json')
      expect(subject).to have_received(:emit_error)
        .with('Could not parse the response')
        .exactly(1).times
    end
  end
end
