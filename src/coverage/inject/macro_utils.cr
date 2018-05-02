module MacroUtils
  def propagate_location_in_macro(node : Crystal::ASTNode, location : Nil)
    return nil
  end

  def propagate_location_in_macro(node : Crystal::Nop, location : Crystal::Location)
    return location
  end

  def propagate_location_in_macro(node : Crystal::MacroIf, location : Crystal::Location)
    location = location.clone

    node.then.location = location
    location = propagate_location_in_macro(node.then, location)

    node.else.location = location
    location = propagate_location_in_macro(node.else, location)
    return location
  end

  def propagate_location_in_macro(node : Crystal::MacroFor, location : Crystal::Location)
    location = location.clone

    node.body.location = location
    location = propagate_location_in_macro(node.body, location)

    return location
  end

  def propagate_location_in_macro(node : Crystal::MacroLiteral, location : Crystal::Location)
    node.location = location

    new_loc = location.clone line_number: location.line_number + node.to_s.count('\n')

    return new_loc
  end

  def propagate_location_in_macro(node : Crystal::Expressions, location)
    new_loc = location.clone

    node.expressions.each do |e|
      e.location = new_loc
      new_loc = propagate_location_in_macro(e, new_loc)
    end

    return new_loc
  end

  def propagate_location_in_macro(node : Crystal::ASTNode, location : Crystal::Location)
    return location
  end
end
