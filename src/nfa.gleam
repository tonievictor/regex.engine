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

pub fn compute(engine: EngineNFA, value: String) -> Bool {
  let assert Ok(c) = dict.get(engine.states, engine.initial_state)
  let stack = list.prepend([], StackValue(i: 0, current_state: c))

  case stack {
    [] -> False
    rest -> {
      let assert Ok(c) = list.last(rest)
      case
        list.find(engine.ending_states, fn(x) { x == c.current_state.name })
      {
        Ok(_) -> True
        Error(_) -> {
          let input = string.slice(value, c.i, 1)
          process_transitions(
            list.reverse(c.current_state.transitions),
            stack,
            input,
            c.i,
          )
          io.debug(c.current_state.name)
          False
        }
      }
    }
  }
}

fn process_transitions(
  transitions: List(state.Transition),
  stack: List(StackValue),
  input: String,
  index: Int,
) -> List(StackValue) {
  case list.reverse(transitions) {
    [] -> stack
    [#(matcher, to_state), ..rest] -> {
      case state.matches(matcher, input) {
        True -> {
          let i = case state.is_epilson(matcher) {
            True -> index
            False -> index + 1
          }
          process_transitions(
            rest,
            list.prepend(stack, StackValue(i: i, current_state: to_state)),
            input,
            i,
          )
        }
        False -> process_transitions(rest, stack, input, index)
      }
    }
  }
}
