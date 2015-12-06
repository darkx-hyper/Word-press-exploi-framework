require_relative '../spec_helper'
include Wpxf::Net::HTTPOptions

describe Wpxf::Net::HttpClient do
  # Dummy class for tests.
  class Subject < Wpxf::Module
    include Wpxf::Net::HttpClient
    include Wpxf::Net::TyphoeusHelper
  end

  let(:subject) { Subject.new }

  describe '#advanced_typhoeus_options' do
    it 'contains Typhoeus options using values in the datastore' do
      subject.set_option_value('BasicAuthCreds', 'root:toor')
      subject.set_option_value('Proxy', '127.0.0.1')
      subject.set_option_value('ProxyAuthCreds', 'root:toor')
      subject.set_option_value('HostVerification', true)
      subject.set_option_value('HTTPClientTimeout', 10_000)

      expect(subject.advanced_typhoeus_options).to include(
        userpwd: 'root:toor',
        proxy: '127.0.0.1',
        proxyuserpwd: 'root:toor',
        ssl_verifyhost: 2,
        timeout: 10_000
      )
    end
  end

  describe '#standard_typhoeus_options' do
    it 'contains Tphoeus options using values in the datastore' do
      method = :get
      body = 'body'
      params = ['foo=bar']
      headers = { 'Foo' => 'Bar' }
      base_headers = subject.base_http_headers

      subject.set_option_value('FollowHTTPRedirection', true)
      opts = subject.standard_typhoeus_options(method, params, body, headers)

      expect(opts).to include(
        method: method,
        body: body,
        params: params,
        headers: base_headers.merge(headers),
        followlocation: true
      )
    end
  end

  describe '#create_typhoeus_request_options' do
    it 'returns a merge of the standard and advanced request options' do
      method = :get
      body = 'body'
      params = ['foo=bar']
      headers = { 'Foo' => 'Bar' }

      expect(
        subject.create_typhoeus_request_options(method, params, body, headers)
      ).to eq(
        subject.standard_typhoeus_options(method, params, body, headers)
          .merge(subject.advanced_typhoeus_options)
      )
    end
  end

  describe '#create_typhoeus_request' do
    it 'returns a Typhoeus request' do
      expect(subject.create_typhoeus_request(:get, 'github.com', nil, nil, {}))
        .to be_a Typhoeus::Request
    end
  end
end
