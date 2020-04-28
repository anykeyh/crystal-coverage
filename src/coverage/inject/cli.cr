require "option_parser"
require "log"

module Coverage
  module CLI
    Log = ::Log.for("cli")

    def self.run
      output_format = "HtmlReport"
      targets = [] of String
      print_only = false

      OptionParser.parse! do |parser|
        parser.banner = "Usage: crystal-coverage [options] <directories or filenames>"
        parser.on("-h", "--help", "show this help") { puts parser; exit }
        parser.on("-o FORMAT", "--output-format=FORMAT", "The output format used (default: HtmlReport): HtmlReport, Coveralls ") { |f| output_format = f }
        parser.on("-p", "--print-only", "output the generated source code") { |_p| print_only = true }
        parser.on("--use-require=REQUIRE", "change the require of cover library in runtime") { |r| Coverage::SourceFile.use_require = r }
        parser.unknown_args do |args|
          args.each do
            targets << ARGV.shift
          end
        end
      end

      Log.error { "You must choose at least one file to compile" } unless targets.any?

      Coverage::SourceFile.outputter = "Coverage::Outputter::#{output_format.camelcase}"

      filenames = targets.map do |target|
        target += "/**/*.cr" if File.directory?(target)
        Dir[target]
      end.flatten.uniq!

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
