class Test
  def foo
    n = 1
    while (n < 10)
      n += 1
      puts "foo!"
    end
  end

  def bar
    begin
      x = 1

      x = x + 1
      raise "Code below will never be covered"

      puts "Some code below"
    rescue
    end
  end
end

test = Test.new

test.foo
