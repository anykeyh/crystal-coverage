require "ecr"
require "file_utils"
require "html"

class Coverage::Outputter::HtmlReport < Coverage::Outputter
  struct CoverageReport
    property filename : String
    property md5 : String
    property relevant_lines : Int32 = 0
    property covered_lines : Int32 = 0
    property lines : Array(Tuple(String, Int32?)) = [] of Tuple(String, Int32?)

    def initialize(@filename, @md5)
    end

    def percent_coverage
      if relevant_lines == 0
        1.0
      else
        (covered_lines / relevant_lines.to_f)
      end
    end

    def percent_coverage_str
      "#{(100*percent_coverage).round(2)} %"
    end
  end

  class IndexFile
    def initialize(@covered_files : Array(CoverageReport))
    end

    {% begin %}
      {% x = __DIR__ + "/../../../../template" %}
      ECR.def_to_s "{{x.id}}/index.html.ecr"
    {% end %}
  end

  class SummaryFile
    property total_relevant : Int32
    property total_covered : Int32

    def total_percentage
      if total_relevant == 0
        100.0
      else
        (100.0*(total_covered / total_relevant.to_f)).round(2)
      end
    end

    def percentage_covered_color(cov)
      case cov
      when 90.0..100.0
        "green"
      when 80.0..89.99
        "yellow"
      else
        "red"
      end
    end

    def initialize(@covered_files : Array(CoverageReport), @total_relevant, @total_covered)
    end

    {% begin %}
      {% x = __DIR__ + "/../../../../template" %}
      ECR.def_to_s "{{x.id}}/summary.html.ecr"
    {% end %}
  end

  class CoveredFile
    def initialize(@file : CoverageReport)
    end

    {% begin %}
      {% x = __DIR__ + "/../../../../template" %}
      ECR.def_to_s "{{x.id}}/cover.html.ecr"
    {% end %}
  end

  def initialize
  end

  def output(files : Array(Coverage::File))
    puts "Generating coverage report, please wait..."

    system("rm -r coverage/")

    sum_lines = 0
    sum_covered = 0

    covered_files = files.map do |file|
      hit_counts = {} of Int32 => Int32?

      # Prepare the line hit count
      file.source_map.each_with_index do |line, idx|
        hit_counts[line] = file.access_map[idx]
      end

      # Prepare the coverage report
      f = ::File.read(file.path)
      cr = CoverageReport.new(file.path, file.md5)

      # Add the coverage info for each line of code...
      f.split("\n").each_with_index do |line, line_number|
        line_number = line_number + 1
        hitted = hit_counts[line_number]?

        unless hitted.nil?
          cr.relevant_lines += 1
          cr.covered_lines += hitted > 0 ? 1 : 0
        end

        cr.lines << {line, hitted}
      end

      sum_lines += cr.relevant_lines
      sum_covered += cr.covered_lines

      cr
    end

    # puts percent covered
    if sum_lines == 0
      puts "100% covered"
    else
      puts (100.0*(sum_covered / sum_lines.to_f)).round(2).to_s + "% covered"
    end

    # Generate the code
    FileUtils.mkdir_p("coverage")
    generate_index_file(covered_files)
    generate_summary_file(covered_files, sum_lines, sum_covered)
    covered_files.each do |file|
      generate_detail_file(file)
    end
  end

  private def generate_index_file(covered_files)
    ::File.write("coverage/index.html", IndexFile.new(covered_files).to_s)
  end

  private def generate_summary_file(covered_files, total_lines, covered_lines)
    ::File.write("coverage/summary.html", SummaryFile.new(covered_files, total_lines, covered_lines).to_s)
  end

  private def generate_detail_file(file)
    ::File.write("coverage/#{file.md5}.html", CoveredFile.new(file).to_s)
  end
end
