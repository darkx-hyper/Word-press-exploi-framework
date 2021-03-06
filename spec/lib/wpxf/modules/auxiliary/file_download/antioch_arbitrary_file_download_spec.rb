# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::AntiochArbitraryFileDownload do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_theme_version_from_style)
  end

  it 'should return a {Wpxf::Module}' do
    expect(subject).to be_a Wpxf::Module
  end

  it 'should check the theme is installed' do
    subject.check
    expect(subject).to have_received(:check_theme_version_from_style)
      .with('antioch')
      .exactly(1).times
  end

  it 'should not require authentication' do
    expect(subject.requires_authentication).to be false
  end

  it 'should configure a default remote file path' do
    expected = '../../../../../wp-config.php'
    expect(subject.default_remote_file_path).to eql expected
  end

  it 'should configure the working directory to be antioch/lib/scripts' do
    expected = 'wp-content/themes/antioch/lib/scripts/'
    expect(subject.working_directory).to eql expected
  end

  it 'should configure the downloader url' do
    url_pattern = %r{themes/antioch/lib/scripts/download\.php$}
    expect(subject.downloader_url).to match(url_pattern)
  end

  it 'should configure the request params' do
    subject.set_option_value('remote_file', 'test.php')
    expect(subject.download_request_params).to eql('file' => 'test.php')
  end

  it 'should GET the download request' do
    expect(subject.download_request_method).to eql :get
  end
end
