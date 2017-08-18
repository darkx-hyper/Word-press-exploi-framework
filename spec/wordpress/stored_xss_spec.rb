require_relative '../spec_helper'

describe Wpxf::WordPress::StoredXss do
  let(:subject) do
    Class.new(Wpxf::Module) do
      include Wpxf::WordPress::StoredXss
    end.new
  end

  describe '#new' do
    it 'sets up the desc key of the info store' do
      desc = 'This module stores a script in the target system that '\
             'will execute when an admin user views the vulnerable page, '\
             'which in turn, will create a new admin user to upload '\
             'and execute the selected payload in the context of the '\
             'web server.'

      expect(subject.module_desc).to eq desc
    end
  end

  describe '#run' do
    it 'starts a HTTP server if the module is configured properly' do
      invoked = false
      allow(subject).to receive(:start_http_server) do
        invoked = true
      end

      allow(subject).to receive(:puts).and_return nil
      allow(subject).to receive(:check_wordpress_and_online).and_return true
      allow(subject).to receive(:store_script_and_validate).and_return true
      subject.run
      expect(invoked).to be true
    end

    it 'returns false if #before_store returns false' do
      allow(subject).to receive(:before_store).and_return false
      allow(subject).to receive(:puts).and_return nil
      allow(subject).to receive(:check_wordpress_and_online).and_return true
      allow(subject).to receive(:start_http_server).and_return true

      expect(subject.run).to be false
    end
  end

  describe '#store_script' do
    it 'raises an error if the store_script method isn\'t implemented' do
      expect { subject.store_script }.to raise_error(
        'Required method "store_script" has not been implemented'
      )
    end
  end

  describe '#expected_status_code_after_store' do
    it 'returns 200 by default' do
      expect(subject.expected_status_code_after_store).to eq 200
    end
  end

  describe '#store_script_and_validate' do
    it 'returns false if the response does not match the return value of #expected_status_code_after_store' do
      typhoeus_res = Typhoeus::Response.new
      allow(typhoeus_res).to receive(:code).and_return(404)
      allow(subject).to receive(:expected_status_code_after_store).and_return(200)
      allow(subject).to receive(:store_script).and_return(Wpxf::Net::HttpResponse.new(typhoeus_res))
      expect(subject.store_script_and_validate).to be false
    end

    it 'returns false if the response is nil' do
      allow(subject).to receive(:store_script).and_return(nil)
      expect(subject.store_script_and_validate).to be false
    end

    it 'returns true if the response code matches the return value of #expected_status_code_after_store' do
      typhoeus_res = Typhoeus::Response.new
      allow(typhoeus_res).to receive(:code).and_return(200)
      allow(subject).to receive(:expected_status_code_after_store).and_return(200)
      allow(subject).to receive(:store_script).and_return(Wpxf::Net::HttpResponse.new(typhoeus_res))
      expect(subject.store_script_and_validate).to be true
    end
  end
end
