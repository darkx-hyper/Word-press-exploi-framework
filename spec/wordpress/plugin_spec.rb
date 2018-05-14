# frozen_string_literal: true

require_relative '../spec_helper'

describe Wpxf::WordPress::Plugin do
  let(:body) { '' }
  let(:code) { 200 }
  let(:subject) do
    subject = Class.new(Wpxf::Module) do
      include Wpxf::Net::HttpClient
      include Wpxf::WordPress::Options
      include Wpxf::WordPress::Urls
      include Wpxf::WordPress::Plugin
    end.new

    subject.set_option_value('host', '127.0.0.1')
    subject.set_option_value('target_uri', '/wp/')
    subject.payload = Wpxf::Payload.new
    subject.payload.raw = '<?php echo "hello world"; ?>'
    subject
  end

  before :each do
    res = Wpxf::Net::HttpResponse.new(nil)
    res.body = body
    res.code = code

    allow(subject).to receive(:execute_get_request).and_return(res)
  end

  describe '#fetch_plugin_upload_nonce' do
    let(:body) do
      '<input type="hidden" id="_wpnonce" name="_wpnonce" value="1b76fe9637" />'
    end

    it 'returns an upload nonce if an admin session can be established' do
      expect(subject.fetch_plugin_upload_nonce('')).to eq '1b76fe9637'
    end
  end

  describe '#generate_wordpress_plugin_header' do
    it 'contains all data required to be considered a valid plugin base' do
      script = subject.generate_wordpress_plugin_header('test')
      expect(script).to match(/\*\sPlugin\sName:\stest/)
      expect(script).to match(/\*\sVersion:\s[0-9]\.[0-9]\.[0-9]{2}/)
      expect(script).to match(/\*\sAuthor:\s[a-zA-Z]{10}/)
      expect(script).to match(/\*\sAuthor\sURI:\shttp:\/\/[a-zA-Z]{10}\.com/)
    end
  end

  describe '#wordpress_upload_plugin' do
    it 'returns false if an upload nonce cannot be retrieved' do
      allow(subject).to receive(:fetch_plugin_upload_nonce).and_return nil
      res = subject.upload_payload_as_plugin('test', 'test', 'cookie')
      expect(res).to be false
    end

    it 'returns true if an upload is successful' do
      allow(subject).to receive(:fetch_plugin_upload_nonce).and_return 'a'
      allow(subject).to receive(:execute_post_request) do |opts|
        expect(opts[:url]).to eq subject.wordpress_url_admin_update
        expect(opts[:params]).to eq('action' => 'upload-plugin')
        expect(opts[:cookie]).to eq 'cookie'
        expect(opts[:body]).to include(
          '_wpnonce',
          '_wp_http_referer',
          'pluginzip',
          'install-plugin-submit'
        )

        res = Wpxf::Net::HttpResponse.new(nil)
        res.code = 200
        res
      end

      res = subject.upload_payload_as_plugin('test', 'test', 'cookie')
      expect(res).to be true
    end

    it 'returns false if the response code is not 200' do
      allow(subject).to receive(:fetch_plugin_upload_nonce).and_return 'a'
      allow(subject).to receive(:execute_post_request) do
        res = Wpxf::Net::HttpResponse.new(nil)
        res.code = 404
        res
      end

      res = subject.upload_payload_as_plugin('test', 'test', 'cookie')
      expect(res).to be false
    end
  end

  describe '#upload_payload_as_plugin_and_execute' do
    context 'when the plugin fails to upload' do
      it 'returns nil' do
        res = subject.upload_payload_as_plugin_and_execute('', '', '')
        expect(res).to be_nil
      end
    end

    context 'when the execution returns status 200' do
      let(:code) { 200 }
      let(:body) { 'res content' }
      it 'emits the response content' do
        allow(subject).to receive(:upload_payload_as_plugin).and_return true

        emitted_content = false
        allow(subject).to receive(:emit_success) do |p1|
          emitted_content = p1 == 'Result: res content'
        end

        subject.upload_payload_as_plugin_and_execute('', '', '')
        expect(emitted_content).to be true
      end
    end

    context 'when the payload is executed' do
      it 'returns the HttpResponse of the payload request' do
        allow(subject).to receive(:upload_payload_as_plugin).and_return true
        res = subject.upload_payload_as_plugin_and_execute('', '', '')
        expect(res).to be_kind_of Wpxf::Net::HttpResponse
      end
    end
  end
end
