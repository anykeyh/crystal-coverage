class Crystal::Location
  def clone(filename = nil, line_number = nil, column_number = nil)
    Crystal::Location.new(filename || @filename, line_number || @line_number, column_number || @column_number)
  end
end
