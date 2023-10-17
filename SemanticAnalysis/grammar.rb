require '/Users/ajinkya/Documents/Compiler/ToyLanguageIntepreter/LexicalAnalysis/lexical_analyzer.rb'
require '/Users/ajinkya/Documents/Compiler/ToyLanguageIntepreter/LexicalAnalysis/regex_to_nfa_converter.rb'

module Grammar

  NUMBER = Regexp.new(/[0-9]+/)
  IDENTIFIER = Regexp.new(/[a-zA-Z]/)
  OPERATOR = Regexp.new(/\+|-|\*|\//)
  EPSILON = Regexp.new("epsilon")
  EQUALITY = Regexp.new("=")
  PRINT = Regexp.new("print")
  $terminals = [NUMBER, IDENTIFIER, OPERATOR, EPSILON, EQUALITY, PRINT]
  GrammarMap = {
    "S": [[:stmt, :S], [EPSILON]],
    "stmt": [[:a, :b],[:print]],
    "a":[:id, :eq],
    "b": [[:c], [:id, :op, :var]],
    "c": [[:num, :d]],
    "d": [[:op, :var], [EPSILON]],
    "print":[[:pr, :var]],
    "var": [[:num], [:id]],
    "num": [[NUMBER]],
    "id": [[IDENTIFIER]],
    "eq": [[EQUALITY]],
    "pr": [[PRINT]],
    "op": [[OPERATOR]]
  }

  Symbol_Table_Record = Struct.new(:name, :val)
  Symbol_Table = []

  Production = Struct.new(:symbol, :arr)

  def self.generate_token_stream(filepath)
    token_stream = tokenize(filepath)
    @token_stream = []
    token_stream.each do |token|
      next unless token.name != :spaces
      @token_stream << token
    end
  end

  def self.generate_parse_tree(filepath)
    generate_token_stream(filepath)
    return parse_S(0)
  end

  def self.check_input_string_valid(filepath)
    generate_token_stream(filepath)
    puts @token_stream
    i, @derivations = rec_parse_S(0)
    return i == @token_stream.length, @derivations
  end

  # Predictive parsing algorithm
  # return derivations, i, err
  def self.parse_S(i)
    if i == @token_stream.length
      return [Production.new(:S, [EPSILON])], i, nil
    end
    derivations_from_stmt, i, err = parse_stmt(i)
    if err != nil
      return nil, i, err
    end
    derivations_from_S, i, err = parse_S(i)
    if err != nil
      return nil, i, err
    end
    all_derivations = [Production.new(:S, [:stmt, :S])]
    all_derivations << derivations_from_stmt
    all_derivations << derivations_from_S
    return all_derivations, i, nil
  end

  def self.parse_stmt(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if IDENTIFIER.match(@token_stream[i].val) != nil
      derivations_from_a, i, err = parse_a(i)
      if err != nil
        return nil, i, err
      end
      derivations_from_b, i, err = parse_b(i)
      if err != nil
        return nil, i, err
      end
      all_derivations = [Production.new(:stmt, [:a, :b])]
      all_derivations << derivations_from_a
      all_derivations << derivations_from_b
      return all_derivations, i, nil
    elsif PRINT.match(@token_stream[i].val)
      derivations_from_print, i, err = parse_print(i)
      if err != nil
        return nil, i, err
      end
      all_derivations = [Production.new(:stmt, [:print])]
      all_derivations << derivations_from_print
      return all_derivations, i, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_a(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    all_derivations = [Production.new(:a, [:id, :eq])]
    if IDENTIFIER.match(@token_stream[i].val)
      derivations, i, err = parse_id(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
    end
    if EQUALITY.match(@token_stream[i].val)
      derivations, i, err = parse_eq(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
    end
    return all_derivations, i, err
  end

  def self.parse_b(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if NUMBER.match(@token_stream[i].val)
      all_derivations = [Production.new(:b, [:c])]
      derivations, i, err = parse_c(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      return all_derivations, i, nil
    elsif IDENTIFIER.match(@token_stream[i].val)
      all_derivations = [Production.new(:b, [:id, :op, :var])]
      derivations, i, err = parse_id(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      derivations, i, err = parse_op(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      derivations, i, err = parse_var(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      return all_derivations, i, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_c(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    all_derivations = [Production.new(:c, [:num, :d])]
    if NUMBER.match(@token_stream[i].val)
      derivations, i, err = parse_num(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      derivations, i, err = parse_d(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      return all_derivations, i, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_d(i)
    if i == @token_stream.length
      return [Production.new(:d, [EPSILON])], i, nil
    end
    all_derivations = [Production.new(:d, [:op, :var])]
    if OPERATOR.match(@token_stream[i].val)
      derivations, i, err = parse_op(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      derivations, i, err = parse_var(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      return all_derivations, i, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_print(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    all_derivations = [Production.new(:print, [:pr, :var])]
    if PRINT.match(@token_stream[i].val)
      derivations, i, err = parse_pr(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      derivations, i, err = parse_var(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      return all_derivations, i, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_var(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if NUMBER.match(@token_stream[i].val)
      all_derivations = [Production.new(:var, [:num])]
      derivations, i, err = parse_num(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      return all_derivations, i, nil
    elsif IDENTIFIER.match(@token_stream[i].val)
      all_derivations = [Production.new(:var, [:id])]
      derivations, i, err = parse_id(i)
      if err != nil
        return nil, i, err
      end
      all_derivations << derivations
      return all_derivations, i, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_id(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if IDENTIFIER.match(@token_stream[i].val)
      return [Production.new(:id, [@token_stream[i].val])], i+1, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_eq(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if EQUALITY.match(@token_stream[i].val)
      return [Production.new(:eq, [@token_stream[i].val])], i+1, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_op(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if OPERATOR.match(@token_stream[i].val)
      return [Production.new(:op, [@token_stream[i].val])], i+1, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_num(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if NUMBER.match(@token_stream[i].val)
      return [Production.new(:num, [@token_stream[i].val])], i+1, nil
    else
      return nil, i, "error"
    end
  end

  def self.parse_pr(i)
    if i == @token_stream.length
      return nil, i, "error"
    end
    if PRINT.match(@token_stream[i].val)
      return [Production.new(:pr, [@token_stream[i].val])], i+1, nil
    else
      return nil, i, "error"
    end
  end

  #recursive descent parsing algorithm
  # S -> S1 | S2
  def self.rec_parse_S(i)
    # puts "parse_S"
    j , derivations = parse_S1(i)
    return j, derivations unless j == -1
    return parse_S2(i)
  end

  # func for the production S1 -> stmt S
  def self.parse_S1(i)
    # puts "parse_S1"
    i, derivations_stmt = rec_parse_stmt(i)
    return i, ["error"] if i == -1
    i, derivations_S = rec_parse_S(i)
    return i, [Production.new(:S, [:stmt, :S])].concat(derivations_stmt.concat(derivations_S))
  end

  # S2 -> epsilon
  def self.parse_S2(i)
    # puts "parse_S2"
    return i, [Production.new(:S, [EPSILON])]
  end

  def self.rec_parse_stmt(i)
    # puts "parse_stmt"
    j, derivations = parse_stmt1(i)
    return j, derivations unless j == -1
    return parse_stmt2(i)
  end

  def self.parse_stmt1(i)
    # puts "parse_stmt1"
    i , derivations_a = rec_parse_a(i)
    return i, ["error"] if i == -1
    i, derivations_b = rec_parse_b(i)
    return i, ["error"] if i == -1
    if derivations_b.length == 4
      # if its a decl, add or update var in symbol table
      var_name = derivations_a[1].arr[0]
      val = derivations_b[2].arr[0]
      upsert_sym(var_name, val)
    else
      # if its an operation, get all 3 vars from symbol table and update var in lhs
      # a = b + c
      var_a = derivations_a[1].arr[0]
      if get_sym(var_a) == nil
        puts "error #{var_a} not declared yet"
        return -1, ["error #{var_a} not declared yet"]
      end
      derivations_b.each do |der|
        if der.symbol == :id && get_sym(der.arr[0]) == nil
          puts "error #{der.arr[0]} not declared yet"
          return -1, ["error #{der.arr[0]} not declared yet"]
        end
      end
    end
    return i, [Production.new(:stmt, [:a, :b])].concat(derivations_a.concat(derivations_b))
  end

  def self.parse_stmt2(i)
    # puts "parse_stmt2"
    i, derivations = rec_parse_print(i)
    return i, [Production.new(:stmt, [:print])].concat(derivations)
  end

  def self.rec_parse_a(i)
    # puts "parse_a"
    i, derivations_id = rec_parse_id(i)
    return i, ["error"] if i == -1
    i, derivations_eq = rec_parse_eq(i)
    return i, [Production.new(:a, [:id, :eq])].concat(derivations_id.concat(derivations_eq))
  end

  def self.rec_parse_b(i)
    # puts "parse_b"
    j, derivations = parse_b1(i)
    return j, derivations unless j == -1
    return parse_b2(i)
  end

  def self.rec_parse_print(i)
    # puts "parse_print"
    i, derivations_pr = rec_parse_pr(i)
    return i, ["error"] if i == -1
    i, derivations_var = rec_parse_var(i)
    return i, ["error"] if i == -1
    if IDENTIFIER.match(derivations_var[1].arr[0]) && get_sym(derivations_var[1].arr[0]) == nil
      return -1, ["error"]
    end
    return i, [Production.new(:print, [:pr, :var])].concat(derivations_pr.concat(derivations_var))
  end

  def self.rec_parse_id(i)
    # puts "parse_id"
    if i < @token_stream.length && IDENTIFIER.match(@token_stream[i].val)
      return i+1, [Production.new(:id, [@token_stream[i].val])]
    end
    return -1, ["error"]
  end

  def self.rec_parse_eq(i)
    # puts "parse_eq"
    if i < @token_stream.length && EQUALITY.match(@token_stream[i].val)
      return i+1, [Production.new(:eq, [@token_stream[i].val])]
    end
    return -1, ["error"]
  end

  def self.parse_b1(i)
    # puts "parse_b1"
    i, derivations = rec_parse_c(i)
    return i, [Production.new(:b, [:c])].concat(derivations)
  end

  def self.parse_b2(i)
    # puts "parse_b2"
    derivations = []
    i , derivations_id = rec_parse_id(i)
    return i, ["error"] if i == -1
    i , derivations_op = rec_parse_op(i)
    return i, ["error"] if i == -1
    i, derivations_var = rec_parse_var(i)
    return i, [Production.new(:b, [:id, :op, :var])].concat(derivations.concat(derivations_id).concat(derivations_op).concat(derivations_var))
  end

  def self.rec_parse_pr(i)
    # puts "parse_pr"
    if i < @token_stream.length && PRINT.match(@token_stream[i].val)
      return i+1, [Production.new(:pr, [@token_stream[i].val])]
    end
    return -1, ["error"]
  end

  def self.rec_parse_var(i)
    # puts "parse_var"
    j, derivations = rec_parse_num(i)
    return j, [Production.new(:var, [:num])].concat(derivations) unless j == -1
    j, derivations = rec_parse_id(i)
    return j, [Production.new(:var, [:id])].concat(derivations)
  end

  def self.rec_parse_c(i)
    # puts "parse_c"
    i, derivations_num = rec_parse_num(i)
    return i, ["error"] if i == -1
    i, derivations_d = rec_parse_d(i)
    return i, [Production.new(:c, [:num, :d])].concat(derivations_num.concat(derivations_d))
  end

  def self.rec_parse_op(i)
    # puts "parse_op"
    if i < @token_stream.length && OPERATOR.match(@token_stream[i].val)
      return i+1, [Production.new(:op, [@token_stream[i].val])]
    end
    return -1, ["error"]
  end

  def self.rec_parse_num(i)
    # puts "parse_num"
    if i < @token_stream.length && NUMBER.match(@token_stream[i].val)
      return i+1, [Production.new(:num, [@token_stream[i].val])]
    end
    return -1, ["error"]
  end

  def self.rec_parse_d(i)
    # puts "parse_d"
    j, derivations = parse_d1(i)
    return j, derivations unless j == -1
    return parse_d2(i)
  end

  def self.parse_d2(i)
    # puts "parse_d2"
    return i, [Production.new(:d, [EPSILON])]
  end

  def self.parse_d1(i)
    # puts "parse_d1"
    i, derivations_op = rec_parse_op(i)
    return i, ["error"] if i == -1
    i, derivations_var = rec_parse_var(i)
    return i, [Production.new(:d, [:op, :var])].concat(derivations_op.concat(derivations_var))
  end

  def self.upsert_sym(name, val)
    Symbol_Table.each do |sym|
      if sym.name == name
        sym.val = val
        return
      end
    end
    new_record = Symbol_Table_Record.new(name, val)
    Symbol_Table << new_record
  end

  def self.get_sym(name)
    Symbol_Table.each do |sym|
      return sym if sym.name == name
    end
    return nil
  end
end