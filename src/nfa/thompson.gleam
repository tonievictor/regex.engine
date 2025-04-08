import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import nfa/machine
import nfa/state

pub fn empty_expr() -> machine.NFA {
  machine.new()
  |> machine.declare_states(["q0", "q1"])
  |> machine.set_initial_state("q0")
  |> machine.set_ending_states(["q1"])
  |> machine.add_transition("q0", "q1", state.EpsilonMatcher)
}

pub fn single_char(char: String) -> machine.NFA {
  machine.new()
  |> machine.declare_states(["q0", "q1"])
  |> machine.set_initial_state("q0")
  |> machine.set_ending_states(["q1"])
  |> machine.add_transition("q0", "q1", state.CharacterMatcher(char))
}

pub fn closure(a: machine.NFA) -> machine.NFA {
  machine.declare_states(a, ["p0", "p1"])
  |> machine.set_initial_state("p0")
  |> machine.set_ending_states(["p1"])
  |> machine.add_transition("p0", "p1", state.EpsilonMatcher)
  |> machine.add_transition("p0", "q0", state.EpsilonMatcher)
  |> machine.add_transition("q1", "q0", state.EpsilonMatcher)
  |> machine.add_transition("q1", "p1", state.EpsilonMatcher)
}

pub fn concat(a: machine.NFA, b: machine.NFA) -> machine.NFA {
  let up = update_state_labels(dict.size(a.states), b)
  let assert Ok(last) = list.last(a.ending_states)
  let machine =
    machine.NFA(
      states: dict.merge(a.states, up.states),
      initial_state: a.initial_state,
      ending_states: b.ending_states,
    )
  machine.add_transition(machine, last, b.initial_state, state.EpsilonMatcher)
}

pub fn union() -> machine.NFA {
  todo
}

// I ran into an issue while working on the concat expression.
// To merge two NFAs, I need to combine their states along with their transitions.
// The challenge arises because dictionaries in Gleam require unique keys,
// which complicates the merging process.
// This function addresses that problem.
// We begin by checking the length of the states in 'a'
// and then add that length to the states in 'b'.
// For example, if 'a' has 2 states, we update the states in 'b' as follows:
// q0 becomes q2 (q0 + 2)
// q1 becomes q3 (q1 + 2)
// q2 becomes q4 (q2 + 2), and so on.
fn update_state_labels(i: Int, b: machine.NFA) -> machine.NFA {
  let initial_state = change_label(i, b.initial_state)
  let ending_states = list.map(b.ending_states, fn(a) { change_label(i, a) })
  let states = change_state(dict.to_list(b.states), [], i)

  machine.NFA(
    states: dict.from_list(states),
    initial_state: initial_state,
    ending_states: ending_states,
  )
}

fn change_label(i: Int, label: String) -> String {
  let char = string.slice(label, 0, 1)
  let num = string.slice(label, 1, { string.length(label) - 1 })
  let assert Ok(old) = int.parse(num)
  let new_num = int.to_string(old + i)
  string.join([char, new_num], "")
}

fn change_state(
  states: List(#(String, state.State)),
  output: List(#(String, state.State)),
  i: Int,
) -> List(#(String, state.State)) {
  case states {
    [] -> output
    [#(k, v), ..rest] -> {
      let new_key = change_label(i, k)
      change_state(rest, list.append(output, [#(new_key, v)]), i)
    }
  }
}
