require "./**" # Just to make it loop

module SomeModule
  class SomeClass
    def some_method
      x = 1
      x <<= 3

      x = (x * x + 4_123) % 156
    end

    def self.some_class_method
      begin
        raise "Oops"

        puts "Never get called."
      rescue
        puts "Rescue from raise"
      end
    end
  end
end
