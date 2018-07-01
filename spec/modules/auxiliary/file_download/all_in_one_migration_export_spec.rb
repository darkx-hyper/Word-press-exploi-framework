# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'modules'

describe Wpxf::Auxiliary::AllInOneMigrationExport do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
  end

  it 'should return a {Wpxf::Module}' do
    expect(subject).to be_a Wpxf::Module
  end

  it 'should unregister the remote_file option' do
    expect(subject.get_option('remote_file')).to be_nil
  end

  it 'should re-register the http_client_timeout option with an increased default' do
    expect(subject.get_option('http_client_timeout').default).to eql 300
  end

  it 'should check the plugin version is < 2.0.5' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('all-in-one-wp-migration', '2.0.5')
      .exactly(1).times
  end

  it 'should not require authentication' do
    expect(subject.requires_authentication).to be false
  end

  it 'should download files using the .zip extension' do
    expect(subject.file_extension).to eql '.zip'
  end

  it 'should configure the downloader url' do
    url_pattern = %r{wp-admin/admin-ajax.php$}
    expect(subject.downloader_url).to match(url_pattern)
  end

  it 'should configure the request body' do
    expect(subject.download_request_body).to eql('options[action]' => 'export')
  end

  it 'should configure the request params' do
    expect(subject.download_request_params).to eql('action' => 'router')
  end

  it 'should POST the download request' do
    expect(subject.download_request_method).to eql :post
  end
end
