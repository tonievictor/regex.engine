import gleam/io
import nfa/machine
import nfa/state

pub fn main() {
  let engine =
    machine.new()
    |> machine.declare_states(["q0", "q1", "q2", "q3"])
    |> machine.set_initial_state("q0")
    |> machine.set_ending_states(["q3"])
    |> machine.add_transition("q0", "q2", state.CharacterMatcher("b"))
    |> machine.add_transition("q0", "q1", state.CharacterMatcher("b"))
    |> machine.add_transition("q2", "q3", state.CharacterMatcher("c"))

  io.debug(machine.compute(engine, "bc"))
}
