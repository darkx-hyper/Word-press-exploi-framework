# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::WordPress::FileDownload do
  let(:klass) do
    Class.new(Wpxf::Module) do
      include Wpxf::WordPress::FileDownload
    end
  end

  let(:subject) { klass.new }
  let(:export_path_required) { false }
  let(:http_res) { Wpxf::Net::HttpResponse.new(nil) }

  before :each, 'setup subject' do
    subject.set_option_value('check_wordpress_and_online', false)
    allow(subject).to receive(:working_directory).and_return('wp-content')
    allow(subject).to receive(:download_file).and_return(http_res)
    allow(subject).to receive(:emit_info)
    allow(subject).to receive(:emit_error)
    allow(subject).to receive(:emit_success)
    allow(FileUtils).to receive(:rm)
  end

  describe '#new' do
    it 'should register a generic description' do
      expect(subject.module_desc).to match(/This module exploits a vulnerability/)
    end

    it 'should register the remote_file option' do
      expect(subject.get_option('remote_file')).to_not be_nil
    end
  end

  describe '#working_directory' do
    it 'should return nil by default' do
      subject = klass.new
      expect(subject.working_directory).to be_nil
    end
  end

  describe '#default_remote_file_path' do
    it 'should return nil by default' do
      expect(subject.default_remote_file_path).to be_nil
    end
  end

  describe '#downloader_url' do
    it 'should return nil by default' do
      expect(subject.downloader_url).to be_nil
    end
  end

  describe '#download_request_params' do
    it 'should return nil by default' do
      expect(subject.download_request_params).to be_nil
    end
  end

  describe '#download_request_body' do
    it 'should return nil by default' do
      expect(subject.download_request_body).to be_nil
    end
  end

  describe '#download_request_method' do
    it 'should return :get by default' do
      expect(subject.download_request_method).to eql :get
    end
  end

  describe '#remote_file' do
    it 'should return the value of the remote_file option' do
      subject.set_option_value('remote_file', 'test')
      expect(subject.remote_file).to eql 'test'
    end
  end

  describe '#validate_content' do
    it 'should return true by default' do
      expect(subject.validate_content(nil)).to be true
    end
  end

  describe '#before_download' do
    it 'should return true by default' do
      expect(subject.before_download).to be true
    end
  end

  describe '#file_extension' do
    it 'should return an empty string' do
      expect(subject.file_extension).to eql ''
    end
  end

  describe '#run' do
    context 'if #working_directory is not implemented' do
      it 'should raise an error ' do
        subject = klass.new
        expect { subject.run }.to raise_error('A value must be specified for #working_directory')
      end
    end

    context 'if #before_download returns false' do
      it 'should return false' do
        allow(subject).to receive(:before_download).and_return(false)
        allow(subject).to receive(:working_directory).and_return('wp-content')
        expect(subject.run).to be false
      end
    end

    context 'if the http request is successful' do
      it 'should download the file to a file in the .wpxf directory' do
        http_res.code = 200
        allow(subject).to receive(:_generate_unique_filename).and_return('unique_filename')
        subject.run

        expected = {
          method: subject.download_request_method,
          url: subject.downloader_url,
          params: subject.download_request_params,
          body: subject.download_request_body,
          cookie: subject.session_cookie,
          local_filename: 'unique_filename'
        }

        expect(subject).to have_received(:emit_info).with('Downloading file...')
        expect(subject).to have_received(:download_file)
          .with(expected)
          .exactly(1).times
      end
    end

    context 'if the http request times out' do
      before :each, 'setup response' do
        http_res.timed_out = true
      end

      it 'should emit an error' do
        subject.run
        expect(subject).to have_received(:emit_error)
          .with('Request timed out, try increasing the http_client_timeout')
          .exactly(1).times
      end

      it 'should return false' do
        expect(subject.run).to be false
      end
    end

    context 'if the http response is nil' do
      let(:http_res) { nil }

      it 'should emit an error' do
        subject.run
        expect(subject).to have_received(:emit_error)
          .with('Request timed out, try increasing the http_client_timeout')
          .exactly(1).times
      end

      it 'should return false' do
        expect(subject.run).to be false
      end
    end

    context 'if the #validate_content process fails' do
      before :each, 'setup mocks' do
        http_res.code = 200
        allow(subject).to receive(:validate_content).and_return(false)
      end

      it 'should remove the downloaded file' do
        subject.run
        expect(FileUtils).to have_received(:rm)
          .with(anything, force: true)
          .exactly(1).times
      end

      it 'should return false' do
        expect(subject.run).to be false
      end
    end

    context 'if no errors occur' do
      before :each, 'setup mocks' do
        http_res.code = 200
        allow(subject).to receive(:_generate_unique_filename).and_return('filename')
      end

      it 'should emit a success notice' do
        subject.run
        expect(subject).to have_received(:emit_success)
          .with('Downloaded file to filename')
          .exactly(1).times
      end

      it 'should return true' do
        expect(subject.run).to be true
      end
    end
  end
end
