# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::WpVaultFileDownload do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
  end

  it 'should check that the plugin is installed' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('wp-vault')
      .exactly(1).times
  end

  it 'should configure the default remote file path' do
    expected = '../../../../license.txt'
    expect(subject.default_remote_file_path).to eql expected
  end

  it 'should configure the working directory' do
    expected = 'wp-content/plugins/wp-vault/images/'
    expect(subject.working_directory).to eql expected
  end

  it 'should configure the downloader url' do
    expect(subject.downloader_url).to eql subject.full_uri
  end

  it 'should configure the download request parameters' do
    subject.set_option_value('remote_file', 'license.txt')
    expect(subject.download_request_params).to eql(
      'wpv-image' => 'license.txt'
    )
  end

  it 'should GET the download request' do
    expect(subject.download_request_method).to eql :get
  end
end
