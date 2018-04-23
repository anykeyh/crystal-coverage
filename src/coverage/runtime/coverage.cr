require "json"

module Coverage
  @@files = [] of File
  # Number per file path
  @@reverse_file_index = {} of String => Int32
  class_property file_count : Int32 = 0

  class File
    property path : String
    property source_map : Slice(Int32)
    property access_map : Slice(Int32)
    property! id : Int32
    property md5 : String

    def initialize(@path, @md5, source_map)
      @source_map = Slice(Int32).new(source_map.size) { |x| source_map[x] }
      @access_map = Slice(Int32).new(source_map.size, 0)
      Coverage.add_file(self)
    end

    @[AlwaysInline]
    def [](line_id)
      @access_map.to_unsafe[line_id] += 1
    end
  end

  abstract class Outputter
    abstract def output(files : Array(Coverage::File))
  end

  def self.add_file(file)
    file.id = @@files.size
    @@files << file
    file
  end

  @[AlwaysInline]
  def self.[](file_id, line_id)
    @@files.unsafe_at(file_id)[line_id]
  end

  # Return results of the coverage in JSON
  def self.get_results(outputter : Outputter = Outputter::Text.new)
    outputter.output(@@files)
  end
end
