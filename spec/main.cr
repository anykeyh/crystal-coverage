def main
  if_then_else
  case_when

  k = SomeModule::SomeClass.new
  k.some_method
  SomeModule::SomeClass.some_class_method

  n = 0
  while n < 10
    n += 1
  end
end

require "./**" # Require other files

def if_then_else
  x = "SomeVariable"
  y = 2

  if x == "SomeVariable"
    y = 1
  else
    2 * y
  end
end

def case_when
  x = 2
  case x
  when 1
    "Case 1"
  when 2
    x = "Case 2"
  when x >= 3
    puts "Else cases"
  else
    raise "woops"
  end
end

# Call main
main
