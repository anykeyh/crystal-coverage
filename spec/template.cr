def code
  {% unless true %}
    {% if false %}
      puts "This will not be called"
    {% else %}
      puts "This will be called"
    {% end %}
  {% end %}
end

def for_loop
  {% for x in ["a", "b", "c"] %}
    puts {{x}}
  {% end %}
end
