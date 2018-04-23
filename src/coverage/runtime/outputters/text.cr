class Coverage::Outputter::Text < Coverage::Outputter
  def initialize
  end

  def output(files : Array(Coverage::File))
    puts "file\tlines\tcovered"
    puts "-----------------------------------"

    sum_lines = 0
    sum_covered = 0

    files.each do |file|
      file_line_count = file.access_map.size
      file_line_covered = file.access_map.count(&.>(0))

      coverage_percent = (100 * (
        file_line_count == 0 ? 1 : file_line_covered.to_f / file_line_count
      )).round(2).to_s + "%"

      puts [file.path, file_line_count, file_line_covered, coverage_percent].join("\t")

      sum_lines += file_line_count
      sum_covered += file_line_covered
    end

    puts "-----------------------------------"
    total_percent = (100 * (sum_covered / sum_lines.to_f)).round(2).to_s + "%"
    puts ["TOTAL:", sum_lines, sum_covered, total_percent].join("\t")
  end
end
