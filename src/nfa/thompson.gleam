import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import grammar/lexer.{type Token}
import nfa/machine
import nfa/state

fn empty_expr() -> machine.NFA {
  machine.new()
  |> machine.declare_states(["q0", "q1"])
  |> machine.set_initial_state("q0")
  |> machine.set_ending_states(["q1"])
  |> machine.add_transition("q0", "q1", state.EpsilonMatcher)
}

fn single_char(char: String) -> machine.NFA {
  machine.new()
  |> machine.declare_states(["q0", "q1"])
  |> machine.set_initial_state("q0")
  |> machine.set_ending_states(["q1"])
  |> machine.add_transition("q0", "q1", state.CharacterMatcher(char))
}

fn closure(a: machine.NFA) -> machine.NFA {
  machine.declare_states(a, ["p0", "p1"])
  |> machine.set_initial_state("p0")
  |> machine.set_ending_states(["p1"])
  |> machine.add_transition("p0", "p1", state.EpsilonMatcher)
  |> machine.add_transition("p0", a.initial_state, state.EpsilonMatcher)
  |> from_ending_states(a.ending_states, "p1")
  |> from_ending_states(a.ending_states, a.initial_state)
}

fn concat(a: machine.NFA, b: machine.NFA) -> machine.NFA {
  let up = update_state_labels(dict.size(a.states), b)
  let machine =
    machine.NFA(
      states: dict.merge(a.states, up.states),
      initial_state: a.initial_state,
      ending_states: b.ending_states,
    )
  from_ending_states(machine, a.ending_states, b.initial_state)
}

fn union(a: machine.NFA, b: machine.NFA) -> machine.NFA {
  let states = dict.merge(a.states, b.states)

  machine.NFA(states: states, initial_state: "", ending_states: [])
  |> machine.declare_states(["p0", "p1"])
  |> machine.set_initial_state("p0")
  |> machine.set_ending_states(["p1"])
  |> machine.add_transition("p0", a.initial_state, state.EpsilonMatcher)
  |> machine.add_transition("p0", b.initial_state, state.EpsilonMatcher)
  |> from_ending_states(a.ending_states, "p1")
  |> from_ending_states(b.ending_states, "p1")
}

fn from_ending_states(
  a: machine.NFA,
  states: List(String),
  to: String,
) -> machine.NFA {
  case states {
    [] -> a
    [val, ..rest] -> {
      machine.add_transition(a, val, to, state.EpsilonMatcher)
      |> from_ending_states(rest, to)
    }
  }
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
