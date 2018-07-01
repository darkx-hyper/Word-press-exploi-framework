# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'modules'

describe Wpxf::Auxiliary::DuplicatorCsrfDbExport do
  let(:subject) { described_class.new }
  let(:http_res) { Wpxf::Net::HttpResponse.new(nil) }

  before :each, 'setup subject' do
    allow(subject).to receive(:download_file).and_return(http_res)
    allow(subject).to receive(:check_plugin_version_from_readme)
    allow(subject).to receive(:start_http_server)
    allow(subject).to receive(:puts)
    allow(subject).to receive(:stop_http_server)
    allow(subject).to receive(:sleep)
    allow(subject).to receive(:emit_success)
    subject.set_option_value('check_wordpress_and_online', false)
    subject.set_option_value('target', '127.0.0.1')
    subject.set_option_value('local_host', '127.0.0.1')
    subject.set_option_value('export_path', 'backup.sql')
  end

  it 'should return a {Wpxf::Module}' do
    expect(subject).to be_a Wpxf::Module
  end

  it 'should register a local_host option' do
    expect(subject.get_option('local_host')).to be_a Wpxf::StringOption
  end

  it 'should register a complete_path option' do
    expect(subject.get_option('complete_path')).to be_a Wpxf::StringOption
  end

  it 'should register a export_path option' do
    expect(subject.get_option('export_path')).to be_a Wpxf::StringOption
  end

  it 'should check the plugin is < v1.1.4' do
    subject.check
    expect(subject).to have_received(:check_plugin_version_from_readme)
      .with('duplicator', '1.1.4')
      .exactly(1).times
  end

  it 'should print the initial URL to provide to the victim' do
    subject.run
    expect(subject).to have_received(:puts)
      .with(subject.local_host_base_url)
      .exactly(1).times
  end

  it 'should start a http server to serve the CSRF script' do
    subject.run
    expect(subject).to have_received(:start_http_server).exactly(1).times
  end

  context 'when the initial request is received' do
    it 'should serve the CSRF script' do
      res = subject.on_http_request('/', nil, nil)
      expect(res[:type]).to eql 'text/html'
      expect(res[:body]).to match(/package\-notes=&archive\-format=ZIP&filter\-dirs=&filter\-exts=&dbhost=&dbport=&dbname=&dbuser=&url\-new=/)
    end
  end

  context 'when the callback is received after completing the CSRF request' do
    it 'should initiate the backup download' do
      allow(subject).to receive(:download_backup)
      subject.on_http_request("/#{subject.complete_path}", nil, nil)
      expect(subject).to have_received(:download_backup)
    end
  end

  context 'if the backup fails to download' do
    it 'should leave the module / server running' do
      http_res.code = 404
      subject.download_backup
      expect(subject).to_not have_received(:stop_http_server)
    end
  end

  context 'if the backup download is successful' do
    before :each, 'setup mocks' do
      http_res.code = 200
      subject.download_backup
    end

    it 'should stop the http server' do
      expect(subject).to have_received(:stop_http_server)
    end

    it 'should emit a success message' do
      expect(subject).to have_received(:emit_success)
        .with("Downloaded backup to #{subject.export_path}")
        .exactly(1).times
    end
  end
end
