require "option_parser"
# require "tempfile"

module Coverage
  module CLI
    def self.run
      output_format = "HtmlReport"
      filenames = [] of String
      print_only = false

      OptionParser.parse! do |parser|
        parser.banner = "Usage: crystal-cover [options] <filename>"
        parser.on("-o FORMAT", "--output-format=FORMAT", "The output format used (default: HtmlReport): HtmlReport, Coveralls ") { |f| output_format = f }
        parser.on("-p", "--print-only", "output the generated source code") { |_p| print_only = true }
        parser.on("--use-require=REQUIRE", "change the require of cover library in runtime") { |r| Coverage::SourceFile.use_require = r }
        parser.unknown_args do |args|
          args.each do
            filenames << ARGV.shift
          end
        end
      end

      raise "You must choose a file to compile" unless filenames.any?

      Coverage::SourceFile.outputter = "Coverage::Outputter::#{output_format.camelcase}"

      first = true
      output = String::Builder.new(capacity: 2**18)
      filenames.each do |f|
        v = Coverage::SourceFile.new(path: f, source: ::File.read(f))
        output << v.to_covered_source
        output << "\n"
        first = false
      end

      final_output = [
        Coverage::SourceFile.prelude_operations,
        output.to_s,
        Coverage::SourceFile.final_operations,
      ].join("")

      if print_only
        puts final_output
      else
        system("crystal", ["eval", final_output])
      end
    end
  end
end
