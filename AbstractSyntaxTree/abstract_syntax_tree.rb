require '../SemanticAnalysis/grammar'

class AST
  # define node types
  NODE_S = Struct.new(:s)
  NODE_stmt = Struct.new(:id1, :id2, :op, :id3)
  NODE_a = Struct.new(:id1)
  NODE_b = Struct.new(:id1, :op, :id2)
  NODE_c = Struct.new(:id1, :op, :id2)
  NODE_d = Struct.new(:op, :id1)
  NODE_print = Struct.new(:id1)
  NODE_var = Struct.new(:id1)
  NODE_id = Struct.new(:id1)
  NODE_num = Struct.new(:id1)
  NODE_op = Struct.new(:id1)
  NODE_pr = Struct.new(:id1)
  NODE_eq = Struct.new(:id1)

  NODE = Struct.new(:id, :in_node)
  Terminals = [NODE_id, NODE_num, NODE_op, NODE_pr, NODE_eq]

  def initialize
    # symbol to node map
    @mp = {}
    @mp[:S] = NODE_S
    @mp[:stmt] = NODE_stmt
    @mp[:a] = NODE_a
    @mp[:b] = NODE_b
    @mp[:c] = NODE_c
    @mp[:d] = NODE_d
    @mp[:print] = NODE_print
    @mp[:var] = NODE_var
    @mp[:id] = NODE_id
    @mp[:num] = NODE_num
    @mp[:op] = NODE_op
    @mp[:pr] = NODE_pr
    @mp[:eq] = NODE_eq

    # graph
    @adjacency_matrix = {}

    #node id
    @curr = 0
    @node_map = {}

    #seen map
    # map of node type to node
    @seen = {}
  end

  def generate_AST(filepath)
    valid, @derivations = Grammar.check_input_string_valid(filepath)
    if !valid
      raise "invalid syntax"
      return
    end
    @derivations.each do |der|
      typ = node_type(der.symbol)
      par_node = @seen[typ] == nil ? new_node(der.symbol) : @seen[typ]
      if Terminals.include?(typ)
        par_node.in_node.id1 = der.arr[0]
        next
      end
      der.arr.each do |symbol|
        next if Grammar::EPSILON.match(symbol.to_s)
        child_node = new_node(symbol)
        @adjacency_matrix[par_node.id] = Array.new if @adjacency_matrix[par_node.id] == nil
        @adjacency_matrix[par_node.id] << child_node.id
      end
    end
  end

  def parse_AST(filepath)
    generate_AST(filepath)
    puts @derivations
    puts @adjacency_matrix
    dfs(0)
  end

  private

  def node_type(symbol)
    @mp[symbol]
  end

  def new_node(symbol)
    node_type = @mp[symbol]
    in_node = node_type.new
    tree_node = NODE.new(@curr, in_node)
    @node_map[@curr] = tree_node
    @curr += 1
    @seen[node_type] = tree_node
    tree_node
  end

  def dfs(i)
    if Terminals.include?(@node_map[i].in_node.class) || @adjacency_matrix[i] == nil
      return
    end
    @adjacency_matrix[i].each do |j|
      dfs(j)
    end
    # i is of type S
    if @node_map[i].in_node.class == NODE_S
      return
    end
    # i is of type stmt
    if @node_map[i].in_node.class == NODE_stmt
      # if print stmt
      if @node_map[@adjacency_matrix[i][0]].in_node.class == NODE_print
        j = @adjacency_matrix[i][0]
        var = @node_map[j].in_node.id1
        # execute code
        puts Grammar.get_sym(var).val
        return
      end
      # if decl stmt
      if @node_map[@adjacency_matrix[i][1]].in_node.id2 == nil
        j = @adjacency_matrix[i][0]
        var = @node_map[j].in_node.id1
        k = @adjacency_matrix[i][1]
        val = @node_map[k].in_node.id1
        Grammar.upsert_sym(var, val)
        @node_map[i].in_node.id1 = var
        @node_map[i].in_node.id2 = val
        @node_map[i].in_node.op = '='
        return
      end
      # if expression stmt
      if @node_map[@adjacency_matrix[i][1]].in_node.id2 != nil
        j = @adjacency_matrix[i][0]
        a = @node_map[j].in_node.id1
        k = @adjacency_matrix[i][1]
        b = @node_map[k].in_node.id1
        l = @adjacency_matrix[i][1]
        c = @node_map[l].in_node.id2
        m = @adjacency_matrix[i][1]
        op = @node_map[m].in_node.op
        b_val = b.to_i.to_s == b ? b.to_i : Grammar.get_sym(b).val.to_i
        c_val = c.to_i.to_s == c  ? c.to_i : Grammar.get_sym(c).val.to_i
        if b == nil || c == nil
          raise "rhs of expression is invalid"
        end
        Grammar.upsert_sym(a, evaluate(b_val, c_val, op))
        @node_map[i].in_node.id1 = a
        @node_map[i].in_node.id2 = b
        @node_map[i].in_node.id3 = c
        @node_map[i].in_node.op = op
      end
    end
    # i is of type a
    if @node_map[i].in_node.class == NODE_a
      j = @adjacency_matrix[i][0]
      @node_map[i].in_node.id1 = @node_map[j].in_node.id1
      return
    end
    # i is of type b
    if @node_map[i].in_node.class == NODE_b
      # if b -> c
      if @node_map[@adjacency_matrix[i][0]].in_node.class == NODE_c
        c = @node_map[@adjacency_matrix[i][0]].in_node
        @node_map[i].in_node.id1 = c.id1
        @node_map[i].in_node.id2 = c.id2
        @node_map[i].in_node.op = c.op
        return
      end
      # if b -> id op var
      @node_map[i].in_node.id1 = @node_map[@adjacency_matrix[i][0]].in_node.id1
      @node_map[i].in_node.op = @node_map[@adjacency_matrix[i][1]].in_node.id1
      @node_map[i].in_node.id2 = @node_map[@adjacency_matrix[i][2]].in_node.id1
      return
    end
    # i is of type c
    if @node_map[i].in_node.class ==  NODE_c
      # c -> num
      if @node_map[@adjacency_matrix[i][1]].in_node.id1 == nil
        @node_map[i].in_node.id1 = @node_map[@adjacency_matrix[i][0]].in_node.id1
        return
      end
      # c -> num d
      @node_map[i].in_node.id1 = @node_map[@adjacency_matrix[i][0]].in_node.id1
      @node_map[i].in_node.op = @node_map[@adjacency_matrix[i][1]].in_node.op
      @node_map[i].in_node.id2 = @node_map[@adjacency_matrix[i][1]].in_node.id1
      return
    end
    # i is of type d
    if @node_map[i].in_node.class == NODE_d
      if @adjacency_matrix[i].length == 0
        return
      end
      @node_map[i].in_node.op = @node_map[@adjacency_matrix[i][0]].in_node.id1
      @node_map[i].in_node.id1 = @node_map[@adjacency_matrix[i][1]].in_node.id1
      return
    end
    # i is of type print
    if @node_map[i].in_node.class == NODE_print
      @node_map[i].in_node.id1 = @node_map[@adjacency_matrix[i][1]].in_node.id1
      return
    end
    # i is of type var
    if @node_map[i].in_node.class == NODE_var
      @node_map[i].in_node.id1 = @node_map[@adjacency_matrix[i][0]].in_node.id1
    end
  end

  def evaluate(a, b, op)
    if op == '+'
      return a + b
    end
    if op == '-'
      return a - b
    end
    if op == '*'
      return a*b
    end
    if b == 0
      raise "division by 0"
    end
    return a/b
  end
end
