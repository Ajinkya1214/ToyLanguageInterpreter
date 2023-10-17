class LexicalAnalyzer
  # regex
  KEYWORD = 'print'
  IDENTIFIER = Regexp.new(/\A[a-z]\z/)
  OPERATOR = Regexp.new(/^[=\+]$/)
  CONSTANT = Regexp.new(/\A\d+\z/)
  TOKEN_NAMES_MAP = {}
  IGNOREABLES = Regexp.new(/^[\s\t\n]+$/)
  PARANTHESES = Regexp.new(/\A[()]\z/)
  TOKEN_NAMES_MAP[KEYWORD] = "keyword"
  TOKEN_NAMES_MAP[IDENTIFIER] = "identifier"
  TOKEN_NAMES_MAP[OPERATOR] = "operator"
  TOKEN_NAMES_MAP[CONSTANT] = "constant"
  TOKEN_NAMES_MAP[IGNOREABLES] = "ignoreables"
  TOKEN_NAMES_MAP[PARANTHESES] = "parantheses"

  attr_reader :possible_regex, :tokens_array, :token

  def initialize
    @tokens_array = Array.new
    @possible_regex = [IDENTIFIER, OPERATOR, CONSTANT, IGNOREABLES, PARANTHESES]
    @token = Struct.new(:name, :val)
  end

  def parse_code_file(file_path)
    f = File.open(file_path)
    str = f.read
    puts str
    len = str.length
    curr = ""
    i = 0
    while i < len
      curr += str[i]
      temp = curr
      j = i
      if i < len-1
        temp += str[i+1]
        j += 1
      end
      if find_best_match(temp) != nil
        if temp == "\nb"
          puts "this is the match #{find_best_match(temp)}"
        end
        i = j + 1
        curr = temp
      else
        add_token_to_array(curr)
        i += 1
        curr = ""
      end
    end

    if curr != ""
      add_token_to_array(curr)
    end
  end

  private

  def find_best_match(curr)
    if KEYWORD.start_with?(curr)
      return TOKEN_NAMES_MAP[KEYWORD]
    end
    @possible_regex.each do |regex|
      if curr.match(regex) != nil
        return TOKEN_NAMES_MAP[regex]
      end
    end
    return nil
  end

  def add_token_to_array(curr)
    match = find_best_match(curr)
    if match == nil
      return "error in code #{curr}"
    end
    return if match == TOKEN_NAMES_MAP[IGNOREABLES]
    tokens_array << token.new(match, curr)
  end
end




