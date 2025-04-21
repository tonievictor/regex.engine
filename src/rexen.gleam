import gleam/io
import rexen/grammar
import rexen/nfa/machine
import rexen/nfa/thompson

pub fn main() {
  let assert Ok(engine) = new("a?b")
  io.debug(compute(engine, "a"))
}

pub fn new(expression: String) -> Result(machine.NFA, String) {
  case grammar.shunt(expression) {
    Error(err) -> Error(err)
    Ok(toks) -> {
      thompson.to_nfa(toks)
    }
  }
}

pub fn compute(engine: machine.NFA, input: String) -> Bool {
  machine.evaluate(engine, input)
}
