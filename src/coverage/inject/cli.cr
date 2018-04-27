require "option_parser"

module Coverage
  module CLI
    def self.run
      output_format = "Text"
      filenames = []
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

          args.each do
            filenames << ARGV.shift
          end
        end
      end

      raise "You must choose a file to compile" if filenames.empty?

      Coverage::SourceFile.outputter = "Coverage::Outputter::#{output_format.camelcase}"

      first = true
      output = String::Builder.new(capacity: 2**18)
      filenames.each do |f|
        v = Coverage::SourceFile.new(path: filename, source: ::File.read(filename), is_root: first)
        output << v.to_covered_source
        output << "\n"
        first = false
      end

      if print_only
        puts output.to_s
      else
        system("crystal", ["eval", output.to_s] + ARGV)
      end
    end
  end
end
