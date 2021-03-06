# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require 'wpxf/modules'

describe Wpxf::Auxiliary::GhostUnrestrictedExportDownload do
  let(:subject) { described_class.new }

  before :each, 'setup subject' do
    allow(subject).to receive(:check_plugin_version_from_readme)
    allow(subject).to receive(:emit_error)
    allow(subject).to receive(:emit_table)
    allow(subject).to receive(:emit_success)
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

  it 'should check the plugin version is < 0.5.6' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('ghost', '0.5.6')
      .exactly(1).times
  end

  it 'should specify the file category' do
    expect(subject.file_category).to eql 'database export'
  end

  it 'should not require authentication' do
    expect(subject.requires_authentication).to be false
  end

  it 'should download files using the .json extension' do
    expect(subject.file_extension).to eql '.json'
  end

  it 'should configure the downloader url' do
    url_pattern = %r{wp-admin/tools.php$}
    expect(subject.downloader_url).to match(url_pattern)
  end

  it 'should configure the request params' do
    expect(subject.download_request_params).to eql(
      'ghostexport' => 'true',
      'submit'      => 'Download Ghost file'
    )
  end

  it 'should GET the download request' do
    expect(subject.download_request_method).to eql :get
  end

  it 'should parse the json and print a user table' do
    json = %(
      {
        "data": {
          "users": [{
            "name": "test1",
            "email": "email1"
          }, {
            "name": "test2",
            "email": "email2"
          }]
        }
      })

    expected_table = [
      {
        name: 'Username',
        email: 'E-mail'
      },
      {
        name: 'test1',
        email: 'email1'
      },
      {
        name: 'test2',
        email: 'email2'
      }
    ]

    subject.validate_content(json)
    expect(subject).to have_received(:emit_success)
      .with('Found 2 users')
      .exactly(1).times

    expect(subject).to have_received(:emit_table)
      .with(expected_table)
      .exactly(1).times
  end

  context 'if an error occurs parsing the json' do
    it 'should emit an error' do
      subject.validate_content('{invalid json')
      expect(subject).to have_received(:emit_error)
        .with('Failed to parse the download. The plugin may be disabled or the export may be corrupt.')
        .exactly(1).times
    end
  end
end
