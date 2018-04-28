require "compiler/crystal/syntax/*"
require "digest"
require "file_utils"

class Coverage::SourceFile < Crystal::Visitor
  # List of keywords which are trouble with variable
  # name. Some keywoards are not and won't be present in this
  # list.
  # Since this can break the code replacing the variable by a underscored
  # version of it, and I'm not sure about this list, we will need to add/remove
  # stuff to not break the code.
  CRYSTAL_KEYWORDS = %w(
    abstract do if nil? self unless
    alias else of sizeof until
    as elsif include struct when
    as? end instance_sizeof pointerof super while
    asm ensure is_a? private then with
    begin enum lib protected true yield
    break extend macro require
    case false module rescue typeof
    class for next return uninitialized
    def fun nil select union
  )

  class_getter file_list = [] of Coverage::SourceFile
  class_getter already_covered_file_name = Set(String).new
  class_getter! project_path : String
  class_getter require_expanders = [] of Array(Coverage::SourceFile)
  class_property outputter : String = "Coverage::Outputter::Text"

  getter! astree : Crystal::Parser
  getter id : Int32 = 0
  getter path : String
  getter is_root : Bool
  getter md5_signature : String

  getter lines = [] of Int32
  getter already_covered_locations = Set(Crystal::Location?).new

  getter source : String
  getter! enriched_source : String
  getter required_at : Int32

  def self.register_file(f)
    @@already_covered_file_name.add(f.path)
    @@file_list << f
    @@file_list.size - 1
  end

  def self.relative_path_to_project(path)
    @@project_path ||= FileUtils.pwd
    path.gsub(/^#{Coverage::SourceFile.project_path}\//, "")
  end

  def self.cover_file(file)
    unless already_covered_file_name.includes?(relative_path_to_project(file))
      already_covered_file_name.add(relative_path_to_project(file))
      yield
    end
  end

  def initialize(@path, @source, @is_root = true, @required_at = 0)
    @path = Coverage::SourceFile.relative_path_to_project(File.expand_path(@path, "."))
    @md5_signature = Digest::MD5.hexdigest(@source)
    @id = Coverage::SourceFile.register_file(self)
  end

  # Inject in AST tree if required.
  def process
    unless @astree
      @astree = Crystal::Parser.parse(self.source)
      @astree.accept(self)
    end
  end

  def to_covered_source
    if @enriched_source.nil?
      io = String::Builder.new(capacity: 32_768)

      process
      # To call before injection of cover head dependencies
      main_source = unfold_required(inject_line_traces(astree.to_s))

      io << inject_cover_requirement
      io << main_source
      io << inject_cover_outputting

      @enriched_source = io.to_s
    else
      @enriched_source.not_nil!
    end
  end

  private def unfold_required(output)
    output.gsub(/require[ \t]+\"\$([0-9]+)\"/) do |str, matcher|
      expansion_id = matcher[1].to_i
      file_list = @@require_expanders[expansion_id]

      if file_list.any?
        io = String::Builder.new(capacity: (2 ** 20))
        io << str
        io << "\n"
        file_list.each do |file|
          io << inject_location(file.path, 0) << "\n"
          io << file.to_covered_source
          io << "\n"
          io << inject_location(self.path, file.required_at)
          io << "\n"
        end
        io.to_s
      else
        ""
      end
    end
  end

  private def inject_location(file = @path, line = 0, column = 0)
    %(#<loc:"#{file}",#{line},0>)
  end

  private def inject_cover_requirement
    if @is_root
      file_maps = @@file_list.map do |f|
        if f.lines.any?
          "::Coverage::File.new(\"#{f.path}\", \"#{f.md5_signature}\",[#{f.lines.join(", ")}])"
        else
          "::Coverage::File.new(\"#{f.path}\", \"#{f.md5_signature}\",[] of Int32)"
        end
      end.join("\n")

      <<-RAW
      require "coverage/runtime"
      #{file_maps}
      #{inject_location}

      RAW
    else
      ""
    end
  end

  private def inject_cover_outputting
    @is_root ? "\n::Coverage.get_results(#{@@outputter}.new)" : ""
  end

  private def inject_line_traces(output)
    output.gsub(/\:\:Coverage\[([0-9]+),[ ]*([0-9]+)\]/) do |str, matcher|
      [
        "::Coverage[", matcher[1],
        ", ", matcher[2], "] ",
        inject_location(@path, @lines[matcher[2].to_i] - 1),
      ].join("")
    end
  end

  private def source_map_index(line_number)
    @lines << line_number
    @lines.size - 1
  end

  private def inject_coverage_tracker(node)
    if location = node.location
      lnum = location.line_number
      lidx = source_map_index(lnum)

      n = Crystal::Call.new(Crystal::Global.new("::Coverage"), "[]",
        [Crystal::NumberLiteral.new(@id),
         Crystal::NumberLiteral.new(lidx)].unsafe_as(Array(Crystal::ASTNode)))
      n
    else
      node
    end
  end

  private def force_inject_cover(node : Crystal::ASTNode)
    return node if @already_covered_locations.includes?(node.location)
    already_covered_locations << node.location
    return Crystal::Expressions.from([inject_coverage_tracker(node), node].unsafe_as(Array(Crystal::ASTNode)))
  end

  def inject_cover(node : Crystal::ASTNode)
    return node if already_covered_locations.includes?(node.location)

    case node
    when Crystal::OpAssign, Crystal::Assign, Crystal::BinaryOp
      # We cover assignment
      force_inject_cover(node)
    when Crystal::Call
      # Ignore call to COVERAGE_DOT_CR
      obj = node.obj
      if (node.obj && obj.is_a?(Crystal::Global) && obj.name == "::Coverage")
        return node
      end

      # Be ready to cover the calls
      force_inject_cover(node)
    when Crystal::Break
      force_inject_cover(node)
    else
      return node
    end
  end

  # Management of required file is nasty and should be improved
  # Since I've hard time to replace node on visit,
  # I change the file argument to a number linked to an array of files
  # Then on finalization, we replace each require "xxx" by the proper file.
  def visit(node : Crystal::Require)
    file = node.string
    # we cover only files which are relative to current file
    if file[0] == '.'
      current_directory = Coverage::SourceFile.relative_path_to_project(File.dirname(@path))

      files_to_load = File.expand_path(file, current_directory)

      if files_to_load =~ /\*$/
        # Case when we want to require a directory and subdirectories
        if files_to_load.size > 1 && files_to_load[-2..-1] == "**"
          files_to_load += "/*.cr"
        else
          files_to_load += ".cr"
        end
      elsif files_to_load !~ /\.cr$/
        files_to_load = files_to_load + ".cr" # << Add the extension for the crystal file.
      end

      idx = Coverage::SourceFile.require_expanders.size
      list_of_required_file = [] of Coverage::SourceFile
      Coverage::SourceFile.require_expanders << list_of_required_file

      Dir[files_to_load].each do |file|
        next if file !~ /\.cr$/

        Coverage::SourceFile.cover_file(file) do
          line_number = node.location.not_nil!.line_number

          required_file = Coverage::SourceFile.new(path: file, source: ::File.read(file),
            is_root: false, required_at: line_number)

          required_file.process # Process on load, since it can change the requirement order

          list_of_required_file << required_file
        end
      end

      node.string = "$#{idx}"
    end

    false
  end

  # Do not visit sub elements of inlined computations
  def visit(node : Crystal::OpAssign | Crystal::BinaryOp)
    true
  end

  def visit(node : Crystal::Arg)
    name = node.name
    if CRYSTAL_KEYWORDS.includes?(name)
      node.external_name = node.name = "_#{name}"
    end

    true
  end

  # Placeholder for bug #XXX
  def visit(node : Crystal::Assign)
    target = node.target
    value = node.value

    if target.is_a?(Crystal::InstanceVar) &&
       value.is_a?(Crystal::Var)
      if CRYSTAL_KEYWORDS.includes?(value.name)
        value.name = "_#{value.name}"
      end
    end

    true
  end

  def visit(node : Crystal::Expressions)
    node.expressions = node.expressions.map { |elm| inject_cover(elm) }.flatten
    true
  end

  def visit(node : Crystal::Block | Crystal::While)
    node.body = force_inject_cover(node.body)
    true
  end

  def visit(node : Crystal::Def)
    node.body = force_inject_cover(node.body)
    true
  end

  def visit(node : Crystal::Select)
    node.whens = node.whens.map { |w| Crystal::Select::When.new(body: force_inject_cover(w.body), condition: w.condition) }
    true
  end

  def visit(node : Crystal::Case)
    node.whens = node.whens.map { |w| Crystal::When.new(w.conds, force_inject_cover(w.body)) }
    node.else = force_inject_cover(node.else.not_nil!) if node.else
    true
  end

  def visit(node : Crystal::If)
    unless node.ternary?
      node.then = force_inject_cover(node.then)
      node.else = force_inject_cover(node.else)
    end

    true
  end

  def visit(node : Crystal::Unless)
    node.then = force_inject_cover(node.then)
    node.else = force_inject_cover(node.else)
    true
  end

  # Ignore other nodes for now
  def visit(node : Crystal::ASTNode)
    # puts "#{node.class.name} => " + node.inspect
    true
  end
end
