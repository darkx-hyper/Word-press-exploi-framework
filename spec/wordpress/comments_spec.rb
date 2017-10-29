# frozen_string_literal: true

require_relative '../spec_helper'

describe Wpxf::WordPress::Comments do
  let(:body) { '' }
  let(:headers) { [] }
  let(:code) { 200 }
  let(:subject) do
    subject = Class.new(Wpxf::Module) do
      include Wpxf::Net::HttpClient
      include Wpxf::WordPress::Urls
      include Wpxf::WordPress::Comments
    end.new

    subject.set_option_value('host', '127.0.0.1')
    subject.set_option_value('target_uri', '/wp/')
    subject
  end

  before :each do
    res = Wpxf::Net::HttpResponse.new(nil)
    res.body = body
    res.code = code
    res.headers = headers
    allow(subject).to receive(:execute_get_request).and_return(res)
    allow(subject).to receive(:execute_post_request).and_return(res)
  end

  describe '#wordpress_comments_register_options' do
    it 'registers a set of comment posting related options' do
      subject.wordpress_comments_register_options

      options = [
        'comment_author',
        'comment_content',
        'comment_email',
        'comment_website',
        'comment_post_id'
      ]

      options.each do |o|
        expect(subject.get_option(o)).to_not be_nil
      end
    end
  end

  describe '#wordpress_comments_post?' do
    context 'if the comment ID can be found in the location header' do
      let(:code) { 302 }
      let(:headers) { { 'Location' => 'http://127.0.0.1/wp/hello-world/#comment-3' } }

      it 'returns the comment ID' do
        res = subject.wordpress_comments_post(1, 'content', 'author', 'user@localhost', '')
        expect(res).to eq 3
      end
    end

    context 'if the comment ID was not in the location header' do
      let(:code) { 302 }
      let(:headers) { { 'Location' => 'http://127.0.0.1/wp/hello-world/' } }

      it 'returns -1' do
        res = subject.wordpress_comments_post(1, 'content', 'author', 'user@localhost', '')
        expect(res).to eq(-1)
      end
    end

    context 'if the status code is not 302' do
      let(:code) { 200 }
      it 'returns -1' do
        res = subject.wordpress_comments_post(1, 'content', 'author', 'user@localhost', '')
        expect(res).to eq(-1)
      end
    end
  end
end
