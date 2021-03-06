# frozen_string_literal: true

require_relative '../../../spec_helper'

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

  let(:post_res) { Wpxf::Net::HttpResponse.new(nil) }

  before :each do
    res = Wpxf::Net::HttpResponse.new(nil)
    res.body = body
    res.code = code

    allow(subject).to receive(:execute_get_request).and_return(res)
    allow(subject).to receive(:upload_payload_using_plugin_form).and_call_original
    allow(subject).to receive(:execute_post_request).and_return(post_res)
    allow(subject).to receive(:emit_error)
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
      expect(script).to match(%r{\*\sAuthor\sURI:\shttp://[a-zA-Z]{10}\.com})
    end
  end

  describe '#upload_payload_as_plugin' do
    context 'if an upload nonce cannot be retrieved' do
      it 'should return false' do
        allow(subject).to receive(:fetch_plugin_upload_nonce).and_return nil
        res = subject.upload_payload_as_plugin('test', 'test', 'cookie')
        expect(res).to be false
      end
    end

    context 'if an upload is successful' do
      it 'should return true ' do
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
    end

    context 'if the response code is not 200' do
      it 'should return false' do
        allow(subject).to receive(:fetch_plugin_upload_nonce).and_return 'a'
        post_res.code = 404
        res = subject.upload_payload_as_plugin('test', 'test', 'cookie')
        expect(res).to be false
      end
    end
  end

  describe '#upload_payload_using_plugin_form' do
    context 'if an upload nonce cannot be retrieved' do
      it 'should return false' do
        allow(subject).to receive(:fetch_plugin_upload_nonce).and_return nil
        res = subject.upload_payload_using_plugin_form('test', 'cookie')
        expect(res).to be false
      end
    end

    context 'if an upload is successful' do
      it 'should return true ' do
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

        res = subject.upload_payload_using_plugin_form('test', 'cookie')
        expect(res).to be true
      end
    end

    context 'if the response code is not 200' do
      it 'should return false' do
        allow(subject).to receive(:fetch_plugin_upload_nonce).and_return 'a'
        post_res.code = 404
        res = subject.upload_payload_using_plugin_form('test', 'cookie')
        expect(res).to be false
      end
    end
  end

  describe '#upload_payload_as_plugin_and_execute' do
    context 'when the plugin fails to upload' do
      it 'should attempt to upload the unpackaged payload' do
        subject.upload_payload_as_plugin_and_execute('plugin_name', 'payload_name', 'cookie')
        expect(subject).to have_received(:upload_payload_using_plugin_form)
          .with('payload_name', 'cookie')
          .exactly(1).times
      end

      context 'if both upload attempts fail' do
        it 'should return nil' do
          res = subject.upload_payload_as_plugin_and_execute('', '', '')
          expect(res).to be_nil
        end

        it 'should emit an error' do
          subject.upload_payload_as_plugin_and_execute('', '', '')
          expect(subject).to have_received(:emit_error)
            .with('Failed to upload the payload')
            .exactly(1).times
        end
      end
    end

    context 'if the payload was not packaged as a plugin' do
      it 'should attempt to execute it from the uploads directory' do
        expected_url = "http://127.0.0.1/wp/wp-content/uploads/#{Time.now.strftime('%Y')}/#{Time.now.strftime('%m')}/test.php"
        allow(subject).to receive(:upload_payload_using_plugin_form).and_return(true)
        subject.upload_payload_as_plugin_and_execute('test', 'test', 'cookie')
        expect(subject).to have_received(:execute_get_request)
          .with(url: expected_url)
      end
    end

    context 'if the payload was packaged as a plugin' do
      it 'should attempt to execute it from the plugins directory' do
        expected_url = 'http://127.0.0.1/wp/wp-content/plugins/plugin_name/payload_name.php'
        allow(subject).to receive(:upload_payload_as_plugin).and_return(true)
        subject.upload_payload_as_plugin_and_execute('plugin_name', 'payload_name', 'cookie')
        expect(subject).to have_received(:execute_get_request)
          .with(url: expected_url)
      end
    end

    context 'when the execution returns status 200' do
      let(:code) { 200 }
      let(:body) { 'res content' }

      it 'should emit the response content' do
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
      it 'should return the HttpResponse of the payload request' do
        allow(subject).to receive(:upload_payload_as_plugin).and_return true
        res = subject.upload_payload_as_plugin_and_execute('', '', '')
        expect(res).to be_kind_of Wpxf::Net::HttpResponse
      end
    end
  end
end
