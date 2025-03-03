import gleam/io
import nfa
import parser
import state

pub fn main() {
  let engine =
    nfa.new()
    |> nfa.declare_states(["q0", "q1", "q2", "q3"])
    |> nfa.set_initial_state("q0")
    |> nfa.set_ending_states(["q3"])
    |> nfa.add_trasition("q0", "q1", state.CharacterMatcher("a"))
    |> nfa.add_trasition("q1", "q2", state.CharacterMatcher("b"))
    |> nfa.add_trasition("q2", "q2", state.CharacterMatcher("b"))
    |> nfa.add_trasition("q2", "q3", state.EpsilonMatcher)

  parser.parse("a|b*")
  io.debug(nfa.compute(engine, "abbbbbb"))
}
