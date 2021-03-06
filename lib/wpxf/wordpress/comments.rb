# frozen_string_literal: true

# Provides functionality for gathering and posting comments.
module Wpxf::WordPress::Comments
  include Wpxf

  # Initialises a new instance of {Comments}
  def initialize
    super

    _register_comment_options if should_register_comment_posting_options
  end

  # @return [Boolean] a value indicating whether or not to register
  #   the options required to post a WordPress comment.
  def should_register_comment_posting_options
    true
  end

  # Post a comment.
  # @param post_id [Integer] the post ID to comment on.
  # @param content [String] the content of the comment.
  # @param author [String] the author's name.
  # @param email [String] the author's e-mail address.
  # @param website [String] the author's website.
  # @return [Integer] the ID of the comment, or -1 if the comment failed to post.
  def post_wordpress_comment(post_id, content, author, email, website)
    comment_id = -1

    scoped_option_change('follow_http_redirection', false) do
      res = execute_post_request(
        url: wordpress_url_comments_post,
        cookie: session_cookie,
        body: {
          author: author,
          comment: content,
          email: email,
          url: website,
          submit: 'Post Comment',
          comment_post_ID: post_id,
          comment_parent: 0
        }
      )

      if res&.code == 302
        id = res.headers['Location'][/#comment-([0-9]+)/i, 1]
        comment_id = id.to_i if id
      end
    end

    comment_id
  end

  private

  # Register the comment posting options.
  def _register_comment_options
    register_options([
      StringOption.new(
        name: 'comment_author',
        desc: 'The author name to use when posting a comment',
        default: Utility::Text.rand_alpha(5),
        required: true
      ),
      StringOption.new(
        name: 'comment_content',
        desc: 'The static text to use as the comment content',
        default: Utility::Text.rand_alpha(20),
        required: true
      ),
      StringOption.new(
        name: 'comment_email',
        desc: 'The e-mail address to use when posting a comment',
        default: Utility::Text.rand_email,
        required: true
      ),
      StringOption.new(
        name: 'comment_website',
        desc: 'The website address to use when posting a comment',
        required: false
      ),
      IntegerOption.new(
        name: 'comment_post_id',
        desc: 'The ID of the post to comment on',
        required: true
      )
    ])
  end
end
