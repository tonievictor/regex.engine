import gleam/io
import gleam/string
import grammar/lexer
import grammar/shunt
import nfa

pub fn parse(_engine: nfa.Engine, input: String) {
  let tokens = lexer.tokenize([], input, 0, string.length(input))
  io.debug(lexer.to_string(tokens, ""))
  let assert Ok(toks) = shunt.shunt(tokens, [], [])
  io.debug(lexer.to_string(toks, ""))
}
