import gleam/dict
import gleam/int
import gleam/list
import gleam/string
import grammar.{type Token, Asterix, Letter, Operator, Plus, QMark}
import nfa/machine
import nfa/state

pub fn to_nfa(input: List(Token)) -> Result(machine.NFA, String) {
  to_nfa_loop(input, machine.new(), [])
}

fn to_nfa_loop(
  input: List(Token),
  output: machine.NFA,
  stack: List(machine.NFA),
) -> Result(machine.NFA, String) {
  case input {
    [] -> Ok(output)
    [tok, ..rest] -> {
      case tok {
        Letter(char) -> {
          let o = single_char(char)
          to_nfa_loop(rest, o, list.append(stack, [o]))
        }
        Operator(variant) -> {
          case variant {
            Asterix(_) -> {
              case one_step_stack(stack) {
                Error(err) -> Error(err)
                Ok(#(stk, o)) -> to_nfa_loop(rest, o, stk)
              }
            }
            QMark(_) -> {
              case two_step_nfa(stack, concat) {
                Error(err) -> Error(err)
                Ok(#(stk, o)) -> to_nfa_loop(rest, o, stk)
              }
            }
            Plus(_) -> {
              case two_step_nfa(stack, union) {
                Error(err) -> Error(err)
                Ok(#(stk, o)) -> to_nfa_loop(rest, o, stk)
              }
            }
            _ -> todo
          }
        }
        _ -> todo
      }
    }
  }
}

fn one_step_stack(
  stack: List(machine.NFA),
) -> Result(#(List(machine.NFA), machine.NFA), String) {
  case stack {
    [] -> Error("Stack is not supposed to be empty")
    [val, ..rest] -> {
      let o = closure(val)
      let stk = list.append(rest, [o])
      Ok(#(stk, o))
    }
  }
}

fn two_step_nfa(
  stack: List(machine.NFA),
  func: fn(machine.NFA, machine.NFA) -> machine.NFA,
) -> Result(#(List(machine.NFA), machine.NFA), String) {
  case stack {
    [] -> Error("Stack is not supposed to be empty")
    [_] -> Error("Expected 2 nfa's on the stack, got only one")
    [first, second, ..rest] -> {
      let o = func(first, second)
      let stk = list.append(rest, [o])
      Ok(#(stk, o))
    }
  }
}

fn single_char(char: String) -> machine.NFA {
  machine.new()
  |> machine.declare_states(["q0", "q1"])
  |> machine.set_initial_state("q0")
  |> machine.set_ending_states(["q1"])
  |> machine.add_transition("q0", "q1", state.CharacterMatcher(char))
}

// fn epsilon() -> machine.NFA {
//   machine.new()
//   |> machine.declare_states(["q0", "q1"])
//   |> machine.set_initial_state("q0")
//   |> machine.set_ending_states(["q1"])
//   |> machine.add_transition("q0", "q1", state.EpsilonMatcher)
// }

fn closure(a: machine.NFA) -> machine.NFA {
  let last_state = "q" <> int.to_string(dict.size(a.states) + 1)
  let subject = update_nfa_labels(a, 1)
  machine.declare_states(subject, ["q0", last_state])
  |> transition_ending_states(
    subject.ending_states,
    subject.initial_state,
    state.EpsilonMatcher,
  )
  |> transition_ending_states(subject.ending_states, "q0", state.EpsilonMatcher)
  |> machine.add_transition("q0", subject.initial_state, state.EpsilonMatcher)
  |> machine.add_transition("q0", last_state, state.EpsilonMatcher)
  |> machine.set_initial_state("q0")
  |> machine.set_ending_states([last_state])
}

fn concat(a: machine.NFA, b: machine.NFA) -> machine.NFA {
  let new_b = update_nfa_labels(b, dict.size(a.states))
  machine.NFA(
    states: dict.merge(a.states, new_b.states),
    initial_state: a.initial_state,
    ending_states: new_b.ending_states,
  )
  |> transition_ending_states(
    a.ending_states,
    new_b.initial_state,
    state.EpsilonMatcher,
  )
}

fn union(a: machine.NFA, b: machine.NFA) -> machine.NFA {
  let size_a = dict.size(a.states)
  let size_b = dict.size(b.states)
  let last_state = update_label("q0", 1 + size_a + size_b)
  let new_a = update_nfa_labels(a, 1)
  let new_b = update_nfa_labels(b, 1 + size_a)

  machine.NFA(
    states: dict.merge(new_a.states, new_b.states),
    initial_state: "",
    ending_states: [],
  )
  |> machine.declare_states(["q0", last_state])
  |> machine.set_initial_state("q0")
  |> machine.set_ending_states([last_state])
  |> machine.add_transition("q0", new_a.initial_state, state.EpsilonMatcher)
  |> machine.add_transition("q0", new_b.initial_state, state.EpsilonMatcher)
  |> transition_ending_states(
    new_a.ending_states,
    last_state,
    state.EpsilonMatcher,
  )
  |> transition_ending_states(
    new_b.ending_states,
    last_state,
    state.EpsilonMatcher,
  )
}

fn transition_ending_states(
  m: machine.NFA,
  from: List(String),
  to: String,
  matcher: state.Matcher,
) -> machine.NFA {
  case from {
    [] -> m
    [f, ..rest] -> {
      transition_ending_states(
        machine.add_transition(m, f, to, matcher),
        rest,
        to,
        matcher,
      )
    }
  }
}

fn update_nfa_labels(a: machine.NFA, n: Int) -> machine.NFA {
  let new_states = update_state_labels(dict.to_list(a.states), [], n)
  let new_ending_states = update_ending_state_labels(a.ending_states, [], n)
  machine.NFA(
    states: dict.from_list(new_states),
    initial_state: update_label(a.initial_state, n),
    ending_states: new_ending_states,
  )
}

fn update_ending_state_labels(
  states: List(String),
  output: List(String),
  n: Int,
) -> List(String) {
  case states {
    [] -> output
    [label, ..rest] -> {
      let out = list.append(output, [update_label(label, n)])
      update_ending_state_labels(rest, out, n)
    }
  }
}

fn update_state_labels(
  states: List(#(String, state.State)),
  output: List(#(String, state.State)),
  n: Int,
) -> List(#(String, state.State)) {
  case states {
    [] -> output
    [#(label, state), ..rest] -> {
      let new_label = update_label(label, n)
      let new_transitions = update_transition_labels(state.transitions, [], n)
      let new_state = state.State(name: new_label, transitions: new_transitions)
      let new_out = list.append(output, [#(new_label, new_state)])
      update_state_labels(rest, new_out, n)
    }
  }
}

fn update_transition_labels(
  transitions: List(state.Transition),
  output: List(state.Transition),
  n: Int,
) -> List(state.Transition) {
  case transitions {
    [] -> output
    [#(matcher, state), ..rest] -> {
      let new_state = update_label(state, n)
      let output = list.append(output, [#(matcher, new_state)])
      update_transition_labels(rest, output, n)
    }
  }
}

fn update_label(str: String, n: Int) -> String {
  let assert Ok(number) = int.parse(string.drop_start(str, 1))
  let label = number + n
  string.slice(str, 0, 1) <> int.to_string(label)
}
