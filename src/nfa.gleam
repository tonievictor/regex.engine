import gleam/dict
import state

pub type EngineNFA {
  EngineNFA(
    states: dict.Dict(String, state.State),
    initial_state: state.State,
    ending_states: List(state.State),
  )
}

pub fn set_initial_state(engine: EngineNFA, state: state.State) -> EngineNFA {
  EngineNFA(
    states: engine.states,
    initial_state: state,
    ending_states: engine.ending_states,
  )
}

pub fn set_ending_states(
  engine: EngineNFA,
  ending_states: List(state.State),
) -> EngineNFA {
  EngineNFA(
    states: engine.states,
    initial_state: engine.initial_state,
    ending_states: ending_states,
  )
}

pub fn add_state(engine: EngineNFA, name: String) -> EngineNFA {
  let states = dict.insert(engine.states, name, state.new_state(name))
  EngineNFA(
    states: states,
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
  name: String,
  transition: state.Transition,
) -> EngineNFA {
  let assert Ok(s) = dict.get(engine.states, name)
  let transitions = state.add_transition(s.transitions, transition)
  let new_state =
    state.State(
      name: s.name,
      transitions: transitions,
      end_groups: s.end_groups,
      starts_groups: s.starts_groups,
    )

  EngineNFA(
    states: dict.insert(engine.states, name, new_state),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}

pub fn unshift_transition(
  engine: EngineNFA,
  name: String,
  transition: state.Transition,
) -> EngineNFA {
  let assert Ok(s) = dict.get(engine.states, name)
  let transitions = state.unshift_transistion(s.transitions, transition)
  let new_state =
    state.State(
      name: s.name,
      transitions: transitions,
      end_groups: s.end_groups,
      starts_groups: s.starts_groups,
    )

  EngineNFA(
    states: dict.insert(engine.states, name, new_state),
    initial_state: engine.initial_state,
    ending_states: engine.ending_states,
  )
}
