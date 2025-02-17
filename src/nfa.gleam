import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import state

pub type EngineNFA {
  EngineNFA(
    states: dict.Dict(String, state.State),
    initial_state: String,
    ending_states: List(String),
  )
}

pub fn new() -> EngineNFA {
  EngineNFA(states: dict.new(), initial_state: "", ending_states: [])
}

pub fn set_initial_state(engine: EngineNFA, state: String) -> EngineNFA {
  EngineNFA(
    states: engine.states,
    initial_state: state,
    ending_states: engine.ending_states,
  )
}

pub fn set_ending_states(engine: EngineNFA, values: List(String)) -> EngineNFA {
  EngineNFA(
    states: engine.states,
    initial_state: engine.initial_state,
    ending_states: values,
  )
}

pub fn add_state(engine: EngineNFA, name: String) -> EngineNFA {
  EngineNFA(
    states: dict.insert(engine.states, name, state.new(name)),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}

pub fn declare_states(engine: EngineNFA, names: List(String)) -> EngineNFA {
  case names {
    [] -> engine
    [name, ..rest] -> declare_states(add_state(engine, name), rest)
  }
}

pub fn add_trasition(
  engine: EngineNFA,
  from: String,
  to: String,
  matcher: String,
) -> EngineNFA {
  let assert Ok(to_state) = dict.get(engine.states, to)
  let assert Ok(from_state) = dict.get(engine.states, from)

  let transitions =
    state.add_transition(from_state.transitions, #(matcher, to_state))
  let new_state =
    state.State(
      name: from_state.name,
      transitions: transitions,
      end_groups: from_state.end_groups,
      starts_groups: from_state.starts_groups,
    )

  EngineNFA(
    states: dict.insert(engine.states, from, new_state),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}

pub fn unshift_transistion(
  engine: EngineNFA,
  from: String,
  to: String,
  matcher: String,
) -> EngineNFA {
  let assert Ok(to_state) = dict.get(engine.states, to)
  let assert Ok(from_state) = dict.get(engine.states, from)

  let transitions =
    state.unshift_transistion(from_state.transitions, #(matcher, to_state))
  let new_state =
    state.State(
      name: from_state.name,
      transitions: transitions,
      end_groups: from_state.end_groups,
      starts_groups: from_state.starts_groups,
    )

  EngineNFA(
    states: dict.insert(engine.states, from, new_state),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}

pub type StackValue {
  StackValue(i: Int, current_state: state.State)
}

pub fn compute(engine: EngineNFA, input: String) -> Bool {
  let assert Ok(c) = dict.get(engine.states, engine.initial_state)
  let stack = list.prepend([], StackValue(i: 0, current_state: c))

  process_stack(engine.ending_states, stack, c.transitions, input)
}

fn process_stack(
  ending_states: List(String),
  stack: List(StackValue),
  transitions: List(state.Transition),
  input: String,
) -> Bool {
  io.debug(transitions)
  case stack {
    [] -> False
    [value, ..rest] -> {
      case list.contains(ending_states, value.current_state.name) {
        True -> True
        False -> {
          let char = string.slice(input, value.i, 1)
          let #(new_stack, new_transitions) =
            process_transition(rest, transitions, char, value.i)
          process_stack(ending_states, new_stack, new_transitions, input)
        }
      }
    }
  }
}

fn process_transition(
  stack: List(StackValue),
  transitions: List(state.Transition),
  char: String,
  index: Int,
) -> #(List(StackValue), List(state.Transition)) {
  case list.reverse(transitions) {
    [] -> #(stack, transitions)
    // we are going through the list from the last item, hence the reverse call
    [#(matcher, to_state), ..rest] -> {
      case state.matches(matcher, char) {
        True -> {
          let next_index = case state.is_epsilon(matcher) {
            True -> index
            False -> index + 1
          }
          let new_stack =
            list.prepend(
              stack,
              StackValue(i: next_index, current_state: to_state),
            )
          process_transition(new_stack, to_state.transitions, char, next_index)
        }
        False -> {
          process_transition(stack, rest, char, index)
        }
      }
    }
  }
}
