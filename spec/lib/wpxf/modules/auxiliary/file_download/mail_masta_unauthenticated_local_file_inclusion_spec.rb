# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::MailMastaUnauthenticatedLocalFileInclusion do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
    allow(subject).to receive(:emit_error)
  end

  it 'should return a {Wpxf::Module}' do
    expect(subject).to be_a Wpxf::Module
  end

  it 'should check the plugin is installed' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('mail-masta')
      .exactly(1).times
  end

  it 'should not require authentication' do
    expect(subject.requires_authentication).to be false
  end

  it 'should configure a default remote file path' do
    expected = '/etc/passwd'
    expect(subject.default_remote_file_path).to eql expected
  end

  it 'should configure the working directory' do
    expected = 'wp-content/plugins/mail-masta/inc/campaign'
    expect(subject.working_directory).to eql expected
  end

  it 'should configure the downloader url' do
    url_pattern = %r{plugins/mail-masta/inc/campaign/count_of_send\.php$}
    expect(subject.downloader_url).to match(url_pattern)
  end

  it 'should configure the request params' do
    subject.set_option_value('remote_file', 'test.php')
    expect(subject.download_request_params).to eql(pl: 'test.php')
  end

  it 'should GET the download request' do
    expect(subject.download_request_method).to eql :get
  end
end
