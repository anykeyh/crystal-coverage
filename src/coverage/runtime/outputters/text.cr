class Coverage::TextOutputter < Coverage::Outputter
  def initialize
  end

  private def get_file_list(files, json, io)
    json.array do
      files.each do |file|
        json.object do
          json.field "name", file.path
          json.field "source_digest", file.md5
          json.field "coverage" do
            json.array do
              h = {} of Int32 => Int32?

              file.source_map.each_with_index { |line, idx| h[line] = file.access_map[idx] }

              max_line = file.source_map.max
              max_line.times.map { |x| h[x]? }.each { |x|
                x.nil? ? json.null : json.number(x)
              }
            end
          end
        end
      end
    end
  end

  def output(files : Array(Coverage::File), io)
    files.each do |file|
      file.source_map.each_with_index { |line, idx| file.access_map[idx] ? 0 : 1 }
    end
  end
end
