import gleam/list
import gleeunit/should
import rexen/grammar.{
  type Token, Asterix, Bar, CParen, Dot, Letter, OParen, Operator, QMark,
}

pub fn to_string_test() {
  let tokens = [
    [
      Operator(OParen),
      Letter("a"),
      Operator(Dot(2)),
      Letter("b"),
      CParen,
      Operator(Asterix(3)),
    ],
    [
      Letter("a"),
      Operator(Asterix(3)),
      Letter("b"),
      Operator(Asterix(3)),
      Operator(Dot(2)),
      Letter("c"),
      Operator(Dot(2)),
      Letter("d"),
      Letter("e"),
      Operator(Bar(1)),
      Operator(Dot(2)),
    ],
    [
      Operator(OParen),
      Letter("a"),
      Operator(Dot(2)),
      Letter("b"),
      CParen,
      Operator(QMark(3)),
    ],
  ]
  to_string_loop(tokens, [])
  |> should.equal(["(ab)*", "a*b*cde|", "(ab)?"])
}

fn to_string_loop(
  tokens: List(List(Token)),
  output: List(String),
) -> List(String) {
  case tokens {
    [] -> output
    [toks, ..rest] -> {
      to_string_loop(rest, list.append(output, [grammar.to_string(toks, "")]))
    }
  }
}

pub fn shunt_ok_test() {
  let input = ["(a*b*)c(d|e)", "a|b", "a*b"]
  shunt_ok_loop(input, [])
  |> should.equal([
    [
      Letter("a"),
      Operator(Asterix(3)),
      Letter("b"),
      Operator(Asterix(3)),
      Operator(Dot(2)),
      Letter("c"),
      Operator(Dot(2)),
      Letter("d"),
      Letter("e"),
      Operator(Bar(1)),
      Operator(Dot(2)),
    ],
    [Letter("a"), Letter("b"), Operator(Bar(1))],
    [Letter("a"), Operator(Asterix(3)), Letter("b"), Operator(Dot(2))],
  ])
}

fn shunt_ok_loop(
  input: List(String),
  output: List(List(Token)),
) -> List(List(Token)) {
  case input {
    [] -> output
    [str, ..rest] -> {
      let assert Ok(out) = grammar.shunt(str)
      shunt_ok_loop(rest, list.append(output, [out]))
    }
  }
}

// the shunt function returns an error only when a closing bracket does not
// have a corresponding opening bracket. 
pub fn shunt_test() {
  let input = ["(a*|)", "abab|)"]
  shunt_loop(input, [])
  |> should.equal([True, False])
}

// This append False to the output list when we have an error and True on okay
fn shunt_loop(input: List(String), output: List(Bool)) -> List(Bool) {
  case input {
    [] -> output
    [str, ..rest] -> {
      let out = case grammar.shunt(str) {
        Ok(_) -> True
        Error(_) -> False
      }
      shunt_loop(rest, list.append(output, [out]))
    }
  }
}
