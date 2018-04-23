require "option_parser"

module Coverage
  module CLI
    def self.run
      output_format = "Text"
      filename = ""
      print_only = false

      OptionParser.parse! do |parser|
        parser.banner = "Usage: crystal-cover [options] <filename>"
        parser.on("-o FORMAT", "--output-format=FORMAT", "The output format used") { |f| output_format = f }
        parser.on("-p", "--print-only", "output the generated source code") { |p| print_only = true }
        parser.unknown_args do |args|
          if args.size != 1
            puts parser
            exit
          end

          filename = ARGV.shift
        end
      end

      raise "You must choose a file to compile" if filename == ""

      Coverage::SourceFile.outputter = "Coverage::Outputter::#{output_format.camelcase}"
      v = Coverage::SourceFile.new(path: filename, source: ::File.read(filename))

      if print_only
        puts v.to_covered_source
      else
        system("crystal", ["eval", v.to_covered_source] + ARGV)
      end
    end
  end
end
