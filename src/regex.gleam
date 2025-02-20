import gleam/io
import nfa

pub fn main() {
  let engine =
    nfa.new()
    |> nfa.declare_states(["q0", "q1", "q2", "q3"])
    |> nfa.set_initial_state("q0")
    |> nfa.set_ending_states(["q2"])
    |> nfa.add_trasition("q0", "q1", "a")
    |> nfa.add_trasition("q1", "q2", "b")
    |> nfa.add_trasition("q2", "q2", "b")
    |> nfa.add_trasition("q2", "q3", "ε")

  io.debug(nfa.compute(engine, "abb"))
}
