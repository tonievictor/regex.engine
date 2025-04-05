import gleam/dict
import gleam/list
import gleam/string
import state

pub type Engine {
  Engine(
    states: dict.Dict(String, state.State),
    initial_state: String,
    ending_states: List(String),
  )
}

pub fn new() -> Engine {
  Engine(states: dict.new(), initial_state: "", ending_states: [])
}

pub fn set_initial_state(engine: Engine, state: String) -> Engine {
  Engine(
    states: engine.states,
    initial_state: state,
    ending_states: engine.ending_states,
  )
}

pub fn set_ending_states(engine: Engine, values: List(String)) -> Engine {
  Engine(
    states: engine.states,
    initial_state: engine.initial_state,
    ending_states: values,
  )
}

pub fn add_state(engine: Engine, name: String) -> Engine {
  Engine(
    states: dict.insert(engine.states, name, state.new(name)),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}

pub fn declare_states(engine: Engine, names: List(String)) -> Engine {
  case names {
    [] -> engine
    [name, ..rest] -> declare_states(add_state(engine, name), rest)
  }
}

pub fn add_trasition(
  engine: Engine,
  from: String,
  to: String,
  matcher: state.Matcher,
) -> Engine {
  let assert Ok(from_state) = dict.get(engine.states, from)
  let assert Ok(to_state) = dict.get(engine.states, to)

  let transitions =
    state.add_transition(from_state.transitions, #(matcher, to_state))
  let new_state =
    state.State(
      name: from_state.name,
      transitions: transitions,
      end_groups: from_state.end_groups,
      starts_groups: from_state.starts_groups,
    )

  Engine(
    states: dict.insert(engine.states, from, new_state),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}

pub fn unshift_transistion(
  engine: Engine,
  from: String,
  to: String,
  matcher: state.Matcher,
) -> Engine {
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

  Engine(
    states: dict.insert(engine.states, from, new_state),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}

pub type StackValue {
  StackValue(i: Int, curr_state: state.State)
}

pub fn compute(engine: Engine, input: String) -> Bool {
  let assert Ok(c) = dict.get(engine.states, engine.initial_state)
  let stack = [StackValue(i: 0, curr_state: c)]

  process_stack(engine, stack, input)
}

fn process_stack(engine: Engine, stack: List(StackValue), input: String) -> Bool {
  case stack {
    [] -> False
    [value, ..rest] -> {
      case list.contains(engine.ending_states, value.curr_state.name) {
        True -> True
        False -> {
          let char = string.slice(input, value.i, 1)
          let new_stack =
            process_transitions(
              engine,
              list.reverse(value.curr_state.transitions),
              rest,
              char,
              value.i,
            )
          process_stack(engine, new_stack, input)
        }
      }
    }
  }
}

fn process_transitions(
  engine: Engine,
  transitions: List(state.Transition),
  stack: List(StackValue),
  char: String,
  index: Int,
) -> List(StackValue) {
  case transitions {
    [] -> stack
    [#(matcher, to_state), ..rest] -> {
      case state.matches(matcher, char) {
        True -> {
          let new_index = case state.is_epsilon(matcher) {
            True -> index
            False -> index + 1
          }
          let assert Ok(c) = dict.get(engine.states, to_state.name)
          list.prepend(stack, StackValue(i: new_index, curr_state: c))
        }
        False -> {
          process_transitions(engine, rest, stack, char, index)
        }
      }
    }
  }
}
