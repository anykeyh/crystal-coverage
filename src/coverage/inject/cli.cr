require "option_parser"

module Coverage
  module CLI
    def self.run
      release = false
      output = false
      coverage_file = "./coverage.json"
      filename = ""

      OptionParser.parse! do |parser|
        parser.banner = "Usage: crystal-cover [options] <filename>"
        parser.on("-r", "--release", "Run with release flag") { release = true }
        parser.on("-o", "--output-only", "Output the code only, do not execute it") { |name| destination = name }
        parser.on("-f FILE", "--file=FILE", "File of the coverage file (default: coverage.json)") { |f| file = f }

        parser.unknown_args do |args|
          if args.size != 1
            raise "Usage:  crystal-cover [options] <filename>"
          else
            filename = args[0]
          end
        end
      end

      raise "You must choose a file to compile" if filename == ""

      v = Coverage::SourceFile.new(path: filename, source: ::File.read(filename))
      puts v.to_covered_source
    end
  end
end
