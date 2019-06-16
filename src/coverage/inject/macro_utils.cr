module MacroUtils
  def propagate_location_in_macro(node : Crystal::ASTNode, location : Nil)
    nil
  end

  def propagate_location_in_macro(node : Crystal::Nop, location : Crystal::Location)
    location
  end

  def propagate_location_in_macro(node : Crystal::MacroIf, location : Crystal::Location)
    location = location.clone

    node.then.location = location
    location = propagate_location_in_macro(node.then, location)

    node.else.location = location
    propagate_location_in_macro(node.else, location)
  end

  def propagate_location_in_macro(node : Crystal::MacroFor, location : Crystal::Location)
    location = location.clone

    node.body.location = location
    propagate_location_in_macro(node.body, location)
  end

  def propagate_location_in_macro(node : Crystal::MacroLiteral, location : Crystal::Location)
    node.location = location

    location.clone line_number: location.line_number + node.to_s.count('\n')
  end

  def propagate_location_in_macro(node : Crystal::Expressions, location)
    new_loc = location.clone

    node.expressions.each do |e|
      e.location = new_loc
      new_loc = propagate_location_in_macro(e, new_loc)
    end

    new_loc
  end

  def propagate_location_in_macro(node : Crystal::ASTNode, location : Crystal::Location)
    location
  end
end
