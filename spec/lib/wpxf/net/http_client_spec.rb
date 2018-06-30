# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::Net::HttpClient do
  let(:typhoeus_return_code) { :ok }
  let(:typhoeus_code) { 200 }
  let(:typhoeus_body) { '' }
  let(:typhoeus_headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }
  let(:subject) do
    Class.new(Wpxf::Module) do
      include Wpxf::Net::HttpClient
    end.new
  end

  before :each do
    Typhoeus.stub(/.*/) do
      Typhoeus::Response.new(
        code: typhoeus_code,
        body: typhoeus_body,
        headers: typhoeus_headers,
        return_code: typhoeus_return_code
      )
    end
  end

  describe '#new' do
    it 'registers basic http options' do
      options = [
        HTTP_OPTION_HOST,
        HTTP_OPTION_PORT,
        HTTP_OPTION_VHOST,
        HTTP_OPTION_PROXY,
        HTTP_OPTION_TARGET_URI
      ]

      options.each do |o|
        expect(subject.get_option(o.name)).to_not be_nil
      end
    end

    it 'registers advanced http options' do
      options = [
        HTTP_OPTION_BASIC_AUTH_CREDS,
        HTTP_OPTION_PROXY_AUTH_CREDS,
        HTTP_OPTION_HOST_VERIFICATION,
        HTTP_OPTION_MAX_CONCURRENCY,
        HTTP_OPTION_CLIENT_TIMEOUT,
        HTTP_OPTION_USER_AGENT,
        HTTP_OPTION_FOLLOW_REDIRECT,
        HTTP_OPTION_PEER_VERIFICATION
      ]

      options.each do |o|
        expect(subject.get_option(o.name)).to_not be_nil
      end
    end

    it 'generates a random user agent for the UserAgent option' do
      expect(subject.datastore['user_agent']).to be_a String
    end
  end

  describe '#initialize_options' do
    it 'registers basic http options' do
      options = [
        HTTP_OPTION_HOST,
        HTTP_OPTION_PORT,
        HTTP_OPTION_SSL,
        HTTP_OPTION_VHOST,
        HTTP_OPTION_PROXY,
        HTTP_OPTION_TARGET_URI
      ]

      subject.initialize_options
      options.each do |o|
        expect(subject.get_option(o.name)).to_not be_nil
      end
    end
  end

  describe '#initialize_advanced_options' do
    it 'registers advanced http options' do
      options = [
        HTTP_OPTION_BASIC_AUTH_CREDS,
        HTTP_OPTION_PROXY_AUTH_CREDS,
        HTTP_OPTION_HOST_VERIFICATION,
        HTTP_OPTION_MAX_CONCURRENCY,
        HTTP_OPTION_CLIENT_TIMEOUT,
        HTTP_OPTION_USER_AGENT,
        HTTP_OPTION_FOLLOW_REDIRECT
      ]

      subject.initialize_advanced_options
      options.each do |o|
        expect(subject.get_option(o.name)).to_not be_nil
      end
    end
  end

  describe '#base_http_headers' do
    it 'should always contain a User-Agent header' do
      expect(subject.base_http_headers['User-Agent']).to_not be_nil
    end

    context 'when a VHost is specified' do
      it 'should contain a Host header' do
        subject.set_option_value('vhost', 'github.com')
        expect(subject.base_http_headers['Host']).to eq 'github.com'
      end
    end
  end

  describe '#execute_request' do
    context 'when operation times out' do
      let(:typhoeus_return_code) { :operation_timedout }
      it 'sets the timed_out attribute of the response to true' do
        res = subject.execute_request(
          method: :get,
          url: '127.0.0.1'
        )
        expect(res.timed_out).to be true
      end
    end

    context 'when a connection couldn\'t be established' do
      let(:typhoeus_return_code) { :couldnt_connect }
      it 'sets the timed_out attribute of the response to true' do
        res = subject.execute_request(method: :get, url: 'github.com')
        expect(res.timed_out).to be true
      end
    end

    context 'when a request is successful' do
      it 'returns a HttpResponse' do
        res = subject.execute_request(method: :get, url: 'github.com')
        expect(res.code).to eq typhoeus_code
        expect(res.body).to eq typhoeus_body
        expect(res.headers).to eq typhoeus_headers
        expect(res.timed_out).to eq false
      end
    end
  end

  describe '#execute_get_request' do
    context 'when operation times out' do
      let(:typhoeus_return_code) { :operation_timedout }
      it 'sets the timed_out attribute of the response to true' do
        res = subject.execute_get_request(url: 'github.com')
        expect(res.timed_out).to be true
      end
    end

    context 'when a connection couldn\'t be established' do
      let(:typhoeus_return_code) { :couldnt_connect }
      it 'sets the timed_out attribute of the response to true' do
        expect(subject.execute_get_request(url: 'github.com').timed_out)
          .to be true
      end
    end

    context 'when a request is successful' do
      it 'returns a HttpResponse' do
        res = subject.execute_get_request(url: 'github.com')
        expect(res.code).to eq typhoeus_code
        expect(res.body).to eq typhoeus_body
        expect(res.headers).to eq typhoeus_headers
        expect(res.timed_out).to eq false
      end
    end
  end

  describe '#execute_post_request' do
    context 'when operation times out' do
      let(:typhoeus_return_code) { :operation_timedout }
      it 'sets the timed_out attribute of the response to true' do
        res = subject.execute_post_request(url: 'github.com')
        expect(res.timed_out).to be true
      end
    end

    context 'when a connection couldn\'t be established' do
      let(:typhoeus_return_code) { :couldnt_connect }
      it 'sets the timed_out attribute of the response to true' do
        expect(subject.execute_post_request(url: 'github.com').timed_out)
          .to be true
      end
    end

    context 'when a request is successful' do
      it 'returns a HttpResponse' do
        res = subject.execute_post_request(url: 'github.com')
        expect(res.code).to eq typhoeus_code
        expect(res.body).to eq typhoeus_body
        expect(res.headers).to eq typhoeus_headers
        expect(res.timed_out).to eq false
      end
    end
  end

  describe '#execute_put_request' do
    context 'when operation times out' do
      let(:typhoeus_return_code) { :operation_timedout }
      it 'sets the timed_out attribute of the response to true' do
        res = subject.execute_put_request(url: 'github.com')
        expect(res.timed_out).to be true
      end
    end

    context 'when a connection couldn\'t be established' do
      let(:typhoeus_return_code) { :couldnt_connect }
      it 'sets the timed_out attribute of the response to true' do
        expect(subject.execute_put_request(url: 'github.com').timed_out)
          .to be true
      end
    end

    context 'when a request is successful' do
      it 'returns a HttpResponse' do
        res = subject.execute_put_request(url: 'github.com')
        expect(res.code).to eq typhoeus_code
        expect(res.body).to eq typhoeus_body
        expect(res.headers).to eq typhoeus_headers
        expect(res.timed_out).to eq false
      end
    end
  end

  describe '#execute_delete_request' do
    context 'when operation times out' do
      let(:typhoeus_return_code) { :operation_timedout }
      it 'sets the timed_out attribute of the response to true' do
        res = subject.execute_delete_request(url: 'github.com')
        expect(res.timed_out).to be true
      end
    end

    context 'when a connection couldn\'t be established' do
      let(:typhoeus_return_code) { :couldnt_connect }
      it 'sets the timed_out attribute of the response to true' do
        expect(subject.execute_delete_request(url: 'github.com').timed_out)
          .to be true
      end
    end

    context 'when a request is successful' do
      it 'returns a HttpResponse' do
        res = subject.execute_delete_request(url: 'github.com')
        expect(res.code).to eq typhoeus_code
        expect(res.body).to eq typhoeus_body
        expect(res.headers).to eq typhoeus_headers
        expect(res.timed_out).to eq false
      end
    end
  end

  describe '#target_uri' do
    it 'returns the value of the TargetURI option' do
      subject.set_option_value('target_uri', '/wp-content/vuln.php')
      expect(subject.target_uri).to eq '/wp-content/vuln.php'
    end
  end

  describe '#normalize_uri' do
    it 'starts with a leading forward slash' do
      expect(subject.normalize_uri('a', 'uri', 'path')).to start_with '/'
    end

    it 'joins each part specified with a forward slash' do
      expect(subject.normalize_uri('a', 'uri', 'path')).to eq '/a/uri/path'
    end

    it 'removes duplicate forward slashes' do
      expect(subject.normalize_uri('http://localhost/', '/path')).to eq 'http://localhost/path'
    end
  end

  describe '#target_port' do
    it 'returns the integer value of the Port option' do
      subject.set_option_value('port', 8080)
      expect(subject.target_port).to eq 8080
      expect(subject.target_port).to be_a Integer
    end
  end

  describe '#target_host' do
    it 'returns the value of the Host option' do
      subject.set_option_value('host', 'github.com')
      expect(subject.target_host).to eq 'github.com'
    end
  end

  describe '#full_uri' do
    context 'when the SSL option is set to true' do
      it 'returns the full target uri using the HTTPS scheme' do
        subject.set_option_value('ssl', true)
        subject.set_option_value('host', 'github.com')
        expect(subject.full_uri).to eq 'https://github.com/'
      end
    end

    context 'when the SSL option is set to false' do
      it 'returns the full target uri using the HTTP scheme' do
        subject.set_option_value('ssl', false)
        subject.set_option_value('host', 'github.com')
        expect(subject.full_uri).to eq 'http://github.com/'
      end
    end

    it 'includes the port number in the URI if it is not port 80' do
      subject.set_option_value('port', 8080)
      subject.set_option_value('host', 'github.com')
      expect(subject.full_uri).to eq 'http://github.com:8080/'
    end

    it 'doesn\'t include the port number in the URI if it is port 80' do
      subject.set_option_value('port', 80)
      subject.set_option_value('host', 'github.com')
      expect(subject.full_uri).to eq 'http://github.com/'
    end
  end

  describe '#download_file' do
    let(:typhoeus_body) { 'file contents' }
    it 'downloads a file to the specified location' do
      temp_file = Tempfile.new('foo')
      subject.download_file(
        url: 'http://127.0.0.1',
        method: :get,
        local_filename: temp_file
      )
      expect(File.read(temp_file)).to eq typhoeus_body
    end

    it 'returns a HttpResponse containing the code, headers and body' do
      temp_file = Tempfile.new('foo')
      res = subject.download_file(
        url: 'http://127.0.0.1',
        method: :get,
        local_filename: temp_file
      )
      expect(res.code).to eq typhoeus_code
      expect(res.headers).to eq typhoeus_headers
      expect(res.body).to eq typhoeus_body
    end
  end

  describe '#queue_request' do
    it 'queues a request to be made later by #execute_queued_requests' do
      subject.queue_request(url: 'http://127.0.0.1/foo')
      queue = subject.queue_request(url: 'http://127.0.0.1/bar')
      expect(queue.length).to eq 2
    end
  end

  describe '#normalize_relative_uri' do
    it 'joins the uri on to the value of #full_uri if it starts with a forward slash' do
      allow(subject).to receive(:full_uri).and_return('http://127.0.0.1/path')
      expect(subject.normalize_relative_uri('/test.txt')).to eq 'http://127.0.0.1/path/test.txt'
    end

    it 'uses the full url specified if it does not start with a forward slash' do
      allow(subject).to receive(:full_uri).and_return('http://127.0.0.1/path')
      expect(subject.normalize_relative_uri('www.github.com')).to eq 'www.github.com'
    end
  end
end
