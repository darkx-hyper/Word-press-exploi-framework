# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::WpHideSecurityEnhancerFileDownload do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
    allow(subject).to receive(:emit_error)
  end

  it 'should return a {Wpxf::Module}' do
    expect(subject).to be_a Wpxf::Module
  end

  it 'should check the plugin version is < 1.3.9.3' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('wp-hide-security-enhancer', '1.3.9.3')
      .exactly(1).times
  end

  it 'should register the default remote file path' do
    expected = 'wp-config.php'
    expect(subject.default_remote_file_path).to eql expected
  end

  it 'should not require authentication' do
    expect(subject.requires_authentication).to be false
  end

  it 'should configure the working directory' do
    expected = 'the WordPress installation directory'
    expect(subject.working_directory).to eql expected
  end

  it 'should configure the downloader url' do
    expected = %r{wp\-hide\-security\-enhancer/router/file\-process\.php}
    expect(subject.downloader_url).to match(expected)
  end

  it 'should configure the request params' do
    subject.set_option_value('remote_file', 'wp-config.php')
    expect(subject.download_request_params).to eql(
      'action' => 'style-clean',
      'file_path' => '/wp-config.php'
    )
  end

  it 'should GET the download request' do
    expect(subject.download_request_method).to eql :get
  end

  context 'if no content is received' do
    it 'should emit an error' do
      subject.validate_content('')
      expect(subject).to have_received(:emit_error)
        .with('No content returned, file may not exist.')
        .exactly(1).times
    end

    it 'should fail the validation process' do
      res = subject.validate_content('')
      expect(res).to be false
    end
  end
end
