import gleam/dict
import gleam/list
import gleam/string
import nfa/state

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

pub fn set_initial_state(machine: NFA, state: String) -> NFA {
  NFA(
    states: machine.states,
    initial_state: state,
    ending_states: machine.ending_states,
  )
}

pub fn set_ending_states(machine: NFA, values: List(String)) -> NFA {
  NFA(
    states: machine.states,
    initial_state: machine.initial_state,
    ending_states: values,
  )
}

pub fn add_state(machine: NFA, name: String) -> NFA {
  NFA(
    states: dict.insert(machine.states, name, state.new(name)),
    initial_state: machine.initial_state,
    ending_states: machine.ending_states,
  )
}

pub fn declare_states(machine: NFA, names: List(String)) -> NFA {
  case names {
    [] -> machine
    [name, ..rest] -> declare_states(add_state(machine, name), rest)
  }
}

pub fn add_transition(
  machine: NFA,
  from: String,
  to: String,
  matcher: state.Matcher,
) -> NFA {
  let assert Ok(from_state) = dict.get(machine.states, from)
  let assert Ok(to_state) = dict.get(machine.states, to)

  let transitions =
    state.add_transition(from_state.transitions, #(matcher, to_state))
  let new_state = state.State(name: from_state.name, transitions: transitions)

  NFA(
    states: dict.insert(machine.states, from, new_state),
    initial_state: machine.initial_state,
    ending_states: machine.ending_states,
  )
}

pub type StackValue {
  StackValue(i: Int, state: state.State)
}

pub fn compute(machine: NFA, input: String) -> Bool {
  let assert Ok(c) = dict.get(machine.states, machine.initial_state)
  let stack = [StackValue(i: 0, state: c)]

  process_stack(machine, stack, input)
}

fn process_stack(machine: NFA, stack: List(StackValue), input: String) -> Bool {
  case stack {
    [] -> False
    [value, ..rest] -> {
      case list.contains(machine.ending_states, value.state.name) {
        True -> True
        False -> {
          let char = string.slice(input, value.i, 1)
          let new_stack =
            process_transitions(
              machine,
              list.reverse(value.state.transitions),
              rest,
              char,
              value.i,
              value.state.name,
              [],
            )
          process_stack(machine, new_stack, input)
        }
      }
    }
  }
}

fn process_transitions(
  machine: NFA,
  transitions: List(state.Transition),
  stack: List(StackValue),
  char: String,
  index: Int,
  curr_state: String,
  history: List(String),
) -> List(StackValue) {
  case transitions {
    [] -> stack
    [#(matcher, to_state), ..rest] -> {
      let assert Ok(to_state) = dict.get(machine.states, to_state.name)
      case state.matches(matcher, char) {
        True -> {
          case state.is_epsilon(matcher) {
            True -> {
              case list.contains(history, to_state.name) {
                True -> {
                  process_transitions(
                    machine,
                    rest,
                    list.prepend(stack, StackValue(i: index, state: to_state)),
                    char,
                    index,
                    curr_state,
                    history,
                  )
                }
                False -> {
                  process_transitions(
                    machine,
                    rest,
                    stack,
                    char,
                    index,
                    curr_state,
                    list.append(history, [curr_state]),
                  )
                }
              }
            }
            False -> {
              process_transitions(
                machine,
                rest,
                list.prepend(stack, StackValue(i: index + 1, state: to_state)),
                char,
                index,
                curr_state,
                [],
              )
            }
          }
        }
        False -> {
          process_transitions(
            machine,
            rest,
            stack,
            char,
            index,
            curr_state,
            history,
          )
        }
      }
    }
  }
}
