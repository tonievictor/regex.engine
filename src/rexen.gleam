//// Compile and evaluate regular expressions using Non-deterministic Finite Automata (NFAs).

import rexen/grammar
import rexen/nfa/machine
import rexen/nfa/thompson

/// Compiles a regular expression string into a Non-deterministic Finite Automaton (NFA).
///
/// Takes a regular expression `String` and returns `Ok(NFA)` on success, or `Error(String)` on failure.
/// Uses a shunting-yard algorithm to convert from infix to postfix notation
/// Uses Thompson's construction to construct the nfa
///
/// ## Examples
///
/// ```gleam
/// import rexen
///
/// case rexen.new("a*b") {
///   Ok(_) -> io.println("All good")
///   Error(err) -> io.println(err)
/// }
/// ```
pub fn new(expression: String) -> Result(machine.NFA, String) {
  case grammar.shunt(expression) {
    Error(err) -> Error(err)
    Ok(toks) -> {
      thompson.to_nfa(toks)
    }
  }
}

/// Evaluates whether a given input `String` is matched by the provided Non-deterministic Finite Automaton (NFA).
///
/// Takes an NFA and an input string, returning `True` if the input is accepted by the NFA, and `False` otherwise.
///
/// ## Examples
///
/// ```gleam
/// import rexen
///
/// let assert Ok(nfa) = rexen.new("(a?b)*")
/// rexen.compute(nfa, "ab") // -> True
/// rexen.compute(nfa, "ababab") // -> True
/// rexen.compute(nfa, "ababa") // -> False
/// rexen.compute(nfa, "a") // -> False
/// ```
pub fn compute(engine: machine.NFA, input: String) -> Bool {
  machine.evaluate(engine, input)
}
