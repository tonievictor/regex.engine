import gleam/io
import gleam/list
import gleam/string
import nfa

pub type TokenType {
  Char
  //'a-z'
  Bar
  // '|'
  Asterix
}

pub type Token {
  Token(token_type: TokenType, value: String)
}

pub fn parse(input: String) {
  let tokens = tokenize([], input, 0, string.length(input))
  io.debug(tokens)
}

fn tokenize(
  tokens: List(Token),
  input: String,
  index: Int,
  capacity: Int,
) -> List(Token) {
  case index == capacity {
    True -> tokens
    False -> {
      let curr_char = string.slice(input, index, 1)
      let tok = case curr_char {
        "*" -> Token(Asterix, "*")
        "|" -> Token(Bar, "|")
        _ -> Token(Char, curr_char)
      }
      tokenize(list.append(tokens, [tok]), input, index + 1, capacity)
    }
  }
}

fn to_ast(tokens: List(Token)) {
  todo
}
