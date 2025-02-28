import gleam/list

pub type Transition =
  #(Matcher, State)

pub type State {
  State(
    name: String,
    transitions: List(Transition),
    starts_groups: List(String),
    end_groups: List(String),
  )
}

pub type Matcher {
  CharacterMatcher(char: String)
  EpsilonMatcher
}

pub fn new(name: String) -> State {
  State(name: name, transitions: [], starts_groups: [], end_groups: [])
}

pub fn matches(m: Matcher, c: String) -> Bool {
  case m {
    EpsilonMatcher -> True
    CharacterMatcher(a) -> {
      a == c
    }
  }
}

pub fn is_epsilon(m: Matcher) -> Bool {
  case m {
    EpsilonMatcher -> True
    CharacterMatcher(_) -> False
  }
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
  list.prepend(transitions, transition)
}
