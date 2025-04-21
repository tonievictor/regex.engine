import gleam/dict
import gleam/list
import gleam/string
import rexen/nfa/state

pub type NFA {
  NFA(
    states: dict.Dict(String, state.State),
    initial_state: String,
    ending_states: List(String),
  )
}

pub fn new() -> NFA {
  NFA(states: dict.new(), initial_state: "", ending_states: [])
}

pub fn set_initial_state(nfa: NFA, state: String) -> NFA {
  NFA(
    states: nfa.states,
    initial_state: state,
    ending_states: nfa.ending_states,
  )
}

pub fn set_ending_states(nfa: NFA, values: List(String)) -> NFA {
  NFA(
    states: nfa.states,
    initial_state: nfa.initial_state,
    ending_states: values,
  )
}

pub fn add_state(nfa: NFA, name: String) -> NFA {
  NFA(
    states: dict.insert(nfa.states, name, state.new(name)),
    initial_state: nfa.initial_state,
    ending_states: nfa.ending_states,
  )
}

pub fn declare_states(nfa: NFA, names: List(String)) -> NFA {
  case names {
    [] -> nfa
    [name, ..rest] -> declare_states(add_state(nfa, name), rest)
  }
}

pub fn add_transition(
  nfa: NFA,
  from: String,
  to: String,
  matcher: state.Matcher,
) -> NFA {
  let assert Ok(from_state) = dict.get(nfa.states, from)
  let assert Ok(_) = dict.get(nfa.states, to)

  let transitions = state.add_transition(from_state.transitions, #(matcher, to))
  let new_state = state.State(name: from_state.name, transitions: transitions)

  NFA(
    states: dict.insert(nfa.states, from, new_state),
    initial_state: nfa.initial_state,
    ending_states: nfa.ending_states,
  )
}

pub type StackValue {
  StackValue(i: Int, state: state.State)
}

pub fn evaluate(nfa: NFA, input: String) -> Bool {
  let assert Ok(s) = dict.get(nfa.states, nfa.initial_state)
  let stack = [StackValue(0, s)]
  evaluate_loop(nfa, input, stack)
}

fn evaluate_loop(nfa: NFA, input: String, stack: List(StackValue)) -> Bool {
  case stack {
    [] -> False
    [value, ..rest] -> {
      case list.contains(nfa.ending_states, value.state.name) {
        True ->
          case string.length(input) == value.i {
            True -> True
            False -> {
              let char = string.slice(input, value.i, 1)
              let new_stack =
                process_transitions(
                  nfa,
                  value.state.transitions,
                  rest,
                  value,
                  char,
                )
              evaluate_loop(nfa, input, new_stack)
            }
          }
        False -> {
          let char = string.slice(input, value.i, 1)
          let new_stack =
            process_transitions(nfa, value.state.transitions, rest, value, char)
          evaluate_loop(nfa, input, new_stack)
        }
      }
    }
  }
}

fn process_transitions(
  nfa: NFA,
  transitions: List(state.Transition),
  stack: List(StackValue),
  stkv: StackValue,
  char: String,
) -> List(StackValue) {
  case transitions {
    [] -> stack
    [#(matcher, name), ..rest] -> {
      case state.matches(matcher, char) {
        False -> {
          process_transitions(nfa, rest, stack, stkv, char)
        }
        True -> {
          let index = case state.is_epsilon(matcher) {
            True -> stkv.i
            False -> stkv.i + 1
          }
          let assert Ok(to) = dict.get(nfa.states, name)
          let new_stack = list.append(stack, [StackValue(i: index, state: to)])
          process_transitions(nfa, rest, new_stack, stkv, char)
        }
      }
    }
  }
}
