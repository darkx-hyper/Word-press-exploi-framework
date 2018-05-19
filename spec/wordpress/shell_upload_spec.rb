# frozen_string_literal: true

require_relative '../spec_helper'

describe Wpxf::WordPress::ShellUpload do
  let(:subject) do
    Class.new(Wpxf::Module) do
      include Wpxf::WordPress::ShellUpload
    end.new
  end

  describe '#new' do
    it 'registers the payload_name_length option' do
      expect(subject.get_option('payload_name_length')).to_not be_nil
    end
  end

  describe '#expected_upload_response_code' do
    it 'returns 200' do
      expect(subject.expected_upload_response_code).to eq 200
    end
  end

  describe '#before_upload' do
    it 'returns true' do
      expect(subject.before_upload).to be true
    end
  end

  describe '#possible_payload_upload_locations' do
    it 'returns nil' do
      expect(subject.possible_payload_upload_locations).to be_nil
    end
  end

  describe '#uploaded_payload_location' do
    it 'returns nil' do
      expect(subject.uploaded_payload_location).to be_nil
    end
  end

  describe '#payload_body_builder' do
    it 'returns nil' do
      expect(subject.payload_body_builder).to be_nil
    end
  end

  describe '#uploader_url' do
    it 'returns nil' do
      expect(subject.uploader_url).to be_nil
    end
  end

  describe '#upload_request_params' do
    it 'returns nil' do
      expect(subject.upload_request_params).to be_nil
    end
  end

  describe '#payload_name_extension' do
    it 'returns "php"' do
      expect(subject.payload_name_extension).to eq 'php'
    end
  end

  describe '#validate_upload_result' do
    it 'returns true' do
      expect(subject.validate_upload_result).to be true
    end
  end

  describe '#timestamp_range_adjustment_value' do
    it 'returns 10' do
      expect(subject.timestamp_range_adjustment_value).to eq 10
    end
  end

  describe '#run' do
    let(:before_upload) { true }
    let(:payload_body_builder) { Wpxf::Utility::BodyBuilder.new }
    let(:_upload_payload) { true }
    let(:possible_payload_upload_locations) { [] }

    before(:each) do
      allow(subject).to receive(:before_upload).and_return(before_upload)
      allow(subject).to receive(:payload_body_builder).and_return(payload_body_builder)
      allow(subject).to receive(:_upload_payload).and_return(_upload_payload)
      allow(subject).to receive(:possible_payload_upload_locations).and_return(possible_payload_upload_locations)
      subject.set_option_value('check_wordpress_and_online', false)
    end

    it 'generates a random payload name' do
      subject.run
      expect(subject.payload_name).to_not be_nil
    end

    it 'will execute all possible upload locations until one returns a code != 404' do
      loc1_executed = false
      loc2_executed = false
      loc3_executed = false

      allow(subject).to receive(:_validate_and_prepare_upload_locations).and_return(['loc1', 'loc2', 'loc3'])
      allow(subject).to receive(:execute_payload) do |url|
        res = Wpxf::Net::HttpResponse.new(nil)
        res.code = 404

        if url == 'loc1'
          loc1_executed = true
        elsif url == 'loc2'
          loc2_executed = true
          res.code = 200
        elsif url == 'loc3'
          loc3_executed = true
        end

        res
      end

      subject.run
      expect(loc1_executed).to be true
      expect(loc2_executed).to be true
      expect(loc3_executed).to be false
    end

    context 'when the pre-upload operations fail' do
      let(:before_upload) { false }

      it 'returns false' do
        expect(subject.run).to be false
      end
    end

    context 'when no body builder is created' do
      let(:payload_body_builder) { nil }

      it 'returns false' do
        expect(subject.run).to be false
      end
    end

    context 'if no errors occur' do
      it 'returns true' do
        expect(subject.run).to be true
      end
    end
  end
end
