module Cli
  # Methods for handling output to the screen.
  module Output
    def indent_cursor(level = 1)
      @indent_level += level
      yield
      @indent_level -= level
    end

    def wrap_text(s, width = 78)
      s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n#{@indent * @indent_level}")
    end

    def print_std(msg)
      puts "#{@indent * @indent_level}#{msg}"
    end

    def print_info(msg)
      print "#{@indent * @indent_level}[-] ".light_blue
      puts msg
    end

    def print_good(msg)
      print "#{@indent * @indent_level}[+] ".green
      puts msg
    end

    def print_bad(msg)
      print "#{@indent * @indent_level}[!] ".red
      puts msg
    end

    def print_warning(msg)
      print "#{@indent * @indent_level}[!] ".yellow
      puts msg
    end

    def print_table(data, pad_with_new_lines = false)
      puts '' if pad_with_new_lines
      widths = calculate_col_widths(data)
      data.each_with_index do |row, index|
        print_table_row(row, widths)
        print_header_separator(widths) if index == 0
      end
      puts '' if pad_with_new_lines
    end

    private

    def calculate_col_widths(data)
      widths = {}
      data.each do |row|
        row.keys.each do |col|
          if widths[col].nil? || row[col].to_s.length > widths[col]
            widths[col] = row[col].to_s.length
          end
        end
      end
      widths
    end

    def print_header_separator(widths)
      separators = {}
      widths.keys.each do |col|
        separators[col] = '-' * widths[col]
      end

      print_table_row(separators, widths)
    end

    def print_table_row(data, widths)
      print @indent * @indent_level
      data.keys.each do |col|
        padding = widths[col] - data[col].to_s.length
        print("#{data[col]}#{' ' * padding}   ")
      end
      puts ''
    end
  end
end
