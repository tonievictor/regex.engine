import gleam/io
import nfa
import state

pub fn main() {
  let engine =
    nfa.new()
    |> nfa.declare_states(["q0", "q1", "q2"])
    |> nfa.set_initial_state("q0")
    |> nfa.set_ending_states(["q2"])
    |> nfa.add_trasition("q0", "q1", state.CharacterMatcher("a"))
    |> nfa.add_trasition("q1", "q1", state.EpsilonMatcher)
    |> nfa.add_trasition("q1", "q2", state.CharacterMatcher("c"))

  io.debug(nfa.compute(engine, "abbbbbb"))
  io.debug(nfa.compute(engine, "abbbbbb"))

}
