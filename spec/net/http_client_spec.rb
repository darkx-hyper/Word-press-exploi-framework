require_relative '../spec_helper'
include Wpxf::Net::HTTPOptions

describe Wpxf::Net::HttpClient do
  # Dummy class for tests.
  class Subject < Wpxf::Module
    include Wpxf::Net::HttpClient
  end

  let(:subject) { Subject.new }

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
        HTTP_OPTION_FOLLOW_REDIRECT
      ]

      options.each do |o|
        expect(subject.get_option(o.name)).to_not be_nil
      end
    end

    it 'generates a random user agent for the UserAgent option' do
      expect(subject.datastore['UserAgent']).to be_a String
    end
  end

  describe '#initialize_options' do
    it 'registers basic http options' do
      options = [
        HTTP_OPTION_HOST,
        HTTP_OPTION_PORT,
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
        subject.set_option_value('VHost', 'github.com')
        expect(subject.base_http_headers['Host']).to eq 'github.com'
      end
    end
  end
end
