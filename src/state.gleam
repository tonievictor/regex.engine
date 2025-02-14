import gleam/list

pub type Transition =
  #(String, String)

pub type State {
  State(
    name: String,
    transitions: List(Transition),
    starts_groups: List(String),
    end_groups: List(String),
  )
}

pub fn new_state(name: String) -> State {
  State(name: name, transitions: [], starts_groups: [], end_groups: [])
}

pub fn matches(a: String, c: String) -> Bool {
  a == c
}

pub fn add_transition(
  transitions: List(Transition),
  transition: Transition,
) -> List(Transition) {
  list.append(transitions, [transition])
}

pub fn unshift_transistion(
  transitions: List(Transition),
  transition: Transition,
) -> List(Transition) {
  [transition, ..transitions]
}
