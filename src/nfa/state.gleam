import gleam/list

pub type Transition =
  #(Matcher, String)

pub type State {
  State(name: String, transitions: List(Transition))
}

pub type Matcher {
  CharacterMatcher(char: String)
  EpsilonMatcher
}

pub fn new(name: String) -> State {
  State(name: name, transitions: [])
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
