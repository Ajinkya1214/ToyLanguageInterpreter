module LexicalAnalyzer
  NFA = Struct.new(:start_state, :accepting_states)
  State = Struct.new(:epsilon_transitions, :state_transitions, :is_accepting, :label, :id)
  Token = Struct.new(:name, :val)
  $count = 0

  def new_state
    state  = State.new([], Hash.new, false, nil, $count)
    $count += 1
    state
  end

  def new_nfa(start_state, accepting_states)
    NFA.new(start_state, accepting_states)
  end

  def convert_regex_to_nfa(regex, token_name)
    $count = 0
    stack = []
    regex.each_char do |char|
      if char == '|'
        nfa2 = stack.pop
        nfa1 = stack.pop
        start_state = new_state
        start_state.epsilon_transitions << nfa1.start_state
        start_state.epsilon_transitions << nfa2.start_state
        end_state = new_state
        nfa1.accepting_states.each do |state|
          state.epsilon_transitions << end_state
        end
        nfa2.accepting_states.each do |state|
          state.epsilon_transitions << end_state
        end
        nfa_new = new_nfa(start_state, [end_state])
      elsif char == '^'
        nfa = stack.pop
        start_state = new_state
        start_state.epsilon_transitions << nfa.start_state
        end_state = new_state
        nfa.accepting_states.each do |state|
          state.epsilon_transitions << end_state
        end
        end_state.epsilon_transitions << start_state
        nfa_new = new_nfa(start_state, [end_state])
      elsif char == '.'
        nfa2 = stack.pop
        nfa1 = stack.pop
        nfa1.accepting_states.each do |state|
          state.epsilon_transitions << nfa2.start_state
        end
        nfa_new = new_nfa(nfa1.start_state, nfa2.accepting_states)
      else
        start_state = new_state
        end_state = new_state
        start_state.state_transitions[char] = end_state
        nfa_new = new_nfa(start_state, [end_state])
      end
      stack.push(nfa_new)
    end
    nfa_final = stack.pop
    nfa_final.accepting_states.each do |state|
      state.is_accepting = true
      state.label = token_name
    end
    nfa_final
  end

  def its_a_match(nfa, s)
    curr_states = epsilon_closure([nfa.start_state])
    s.each_char do |char|
      next_states = get_next_states_from_curr_states_and_curr_letter(curr_states, char)
      curr_states = epsilon_closure(next_states)
    end
    accepting = get_accepting_state(curr_states)
    if accepting != nil
      return true
    end
    false
  end

  def get_start_states_from_nfa(nfa)
    arr = []
    q = []
    q.unshift(nfa.start_state)
    while !q.empty?
      state = q.pop
      state.epsilon_transitions.each do |next_state|
        q.unshift(next_state)
      end
      if state.epsilon_transitions.length == 0 || state.is_accepting
        arr << state
      end
    end
    arr
  end

  def tokenize(file_path)
    f = File.open(file_path)
    s = f.read

    all_nfa = get_nfas_for_list_of_regex({keyword: "pr.i.n.t.", identifier: "ab|c|d|e|", constant: "01|2|3|4|^",
                                          operator: "+-|*|/|=|", spaces: "\n\t|\s|^", parenthesis: "()|"})

    curr_states = []
    start_states = []
    #get union of epsilon closures of all nfas
    all_nfa.each do |nfa|
      epsilon_set = epsilon_closure([nfa.start_state])
      curr_states.concat(epsilon_set)
      start_states.concat(epsilon_set)
    end

    #list of tokens generated
    tokens = []
    #running buffer
    buffer = []

    s.each_char do |letter|
      buffer.push(letter)
      next_states = get_next_states_from_curr_states_and_curr_letter(curr_states, letter)
      # if we can go nowhere from curr states using letter, then either
      # a token has been found
      # or there is a syntax error in the code
      if next_states.length == 0
        accepting = get_accepting_state(curr_states)
        if accepting == nil
          raise "Error tokenizing the input"
        end
        # remove letter from the buffer
        buffer.pop
        val = buffer.join
        tokens << Token.new(accepting.label, val)
        buffer = [letter]
        curr_states = get_next_states_from_curr_states_and_curr_letter(start_states, letter)
        next
      else
        curr_states = epsilon_closure(next_states)
      end
    end
    if buffer.length != 0
      accepting = get_accepting_state(curr_states)
      val = buffer.join
      tokens << Token.new(accepting.label, val)
    end
    tokens
  end

  def get_nfas_for_list_of_regex(regex_map)
    nfas = []
    regex_map.each do |name, regex|
      nfas << convert_regex_to_nfa(regex, name)
    end
    nfas
  end

  def get_next_states_from_curr_states_and_curr_letter(curr_states, curr_letter)
    next_states = []
    curr_states.each do |state|
      temp = state.state_transitions[curr_letter]
      next_states << temp unless temp == nil
    end
    return epsilon_closure(next_states)
  end

  def epsilon_closure(states)
    q = []
    closure = []
    visited = {}
    q.concat(states)

    while !q.empty?
      state = q.pop
      closure << state
      visited[state] = true
      state.epsilon_transitions.each do |next_state|
        if visited[next_state]
          next
        end
        q.unshift(next_state)
      end
    end
    closure
  end

  def get_accepting_state(states)
    states.each do |state|
      if state.is_accepting
        return state
      end
    end
    return nil
  end
end






