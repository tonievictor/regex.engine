import gleam/list
import gleam/string

pub type OperatorVariant(prec) {
  OParen
  Asterix(prec)
  Bar(prec)
  Dot(prec)
  QMark(prec)
  Plus(prec)
}

pub type Token {
  CParen
  Letter(char: String)
  Operator(variant: OperatorVariant(Int))
}

fn tokenize(input: List(String), tokens: List(Token)) -> List(Token) {
  case input {
    [] -> tokens
    [char, ..rest] -> {
      let tok = case char {
        "*" -> Operator(Asterix(3))
        "?" -> Operator(QMark(3))
        "+" -> Operator(Plus(3))
        "|" -> Operator(Bar(1))
        "(" -> Operator(OParen)
        ")" -> CParen
        _ -> Letter(char)
      }
      tokenize(rest, list.append(tokens, [tok]))
    }
  }
}

fn add_concat(tokens: List(Token), output: List(Token)) -> List(Token) {
  case tokens {
    [] -> output
    [curr, ..rest] -> {
      case list.last(output) {
        Error(_) -> add_concat(rest, list.append(output, [curr]))
        Ok(prev) -> {
          case prev {
            Letter(_) -> {
              case curr {
                Letter(_) ->
                  add_concat(
                    rest,
                    list.append(output, [Operator(Dot(2)), curr]),
                  )
                CParen -> add_concat(rest, list.append(output, [curr]))
                Operator(variant) -> {
                  case variant {
                    OParen ->
                      add_concat(
                        rest,
                        list.append(output, [Operator(Dot(2)), curr]),
                      )
                    _ -> add_concat(rest, list.append(output, [curr]))
                  }
                }
              }
            }
            CParen -> {
              case curr {
                Letter(_) ->
                  add_concat(
                    rest,
                    list.append(output, [Operator(Dot(2)), curr]),
                  )
                CParen -> add_concat(rest, list.append(output, [curr]))
                Operator(variant) -> {
                  case variant {
                    OParen ->
                      add_concat(
                        rest,
                        list.append(output, [Operator(Dot(2)), curr]),
                      )
                    _ -> add_concat(rest, list.append(output, [curr]))
                  }
                }
              }
            }
            Operator(variant) -> {
              case variant {
                Asterix(_) -> {
                  case curr {
                    Letter(_) ->
                      add_concat(
                        rest,
                        list.append(output, [Operator(Dot(2)), curr]),
                      )
                    CParen -> add_concat(rest, list.append(output, [curr]))
                    Operator(variant) -> {
                      case variant {
                        OParen ->
                          add_concat(
                            rest,
                            list.append(output, [Operator(Dot(2)), curr]),
                          )
                        _ -> add_concat(rest, list.append(output, [curr]))
                      }
                    }
                  }
                }
                _ -> add_concat(rest, list.append(output, [curr]))
              }
            }
          }
        }
      }
    }
  }
}

pub fn to_string(tokens: List(Token), output: String) -> String {
  case tokens {
    [] -> output
    [tok, ..rest] -> {
      case tok {
        CParen -> to_string(rest, string.append(output, ")"))
        Letter(char) -> to_string(rest, string.append(output, char))
        Operator(variant) -> {
          case variant {
            OParen -> to_string(rest, string.append(output, "("))
            Asterix(_) -> to_string(rest, string.append(output, "*"))
            Bar(_) -> to_string(rest, string.append(output, "|"))
            Dot(_) -> to_string(rest, output)
            QMark(_) -> to_string(rest, string.append(output, "?"))
            Plus(_) -> to_string(rest, string.append(output, "+"))
          }
        }
      }
    }
  }
}

// this is an implementation of the Shunting-Yard Algorithm 
// SYA is used to convert the grammar from infix notation to postfix notation
type Stack =
  List(OperatorVariant(Int))

pub fn shunt(input: String) -> Result(List(Token), String) {
  let in = string.to_graphemes(input)
  tokenize(in, [])
  |> add_concat([])
  |> shunt_loop([], [])
}

fn shunt_loop(
  input: List(Token),
  output: List(Token),
  stack: Stack,
) -> Result(List(Token), String) {
  case input {
    [] -> {
      Ok(emptystack(output, stack))
    }
    [tok, ..rest] -> {
      case tok {
        Letter(_) -> shunt_loop(rest, list.append(output, [tok]), stack)
        CParen -> {
          case find_oparen(output, stack) {
            Ok(#(o, s)) -> {
              shunt_loop(rest, o, s)
            }
            Error(err) -> Error(err)
          }
        }
        Operator(opvar) -> {
          case opvar {
            OParen -> shunt_loop(rest, output, list.prepend(stack, opvar))
            Asterix(p) | Bar(p) | Dot(p) | QMark(p) | Plus(p) -> {
              let #(o, s) = handle_operator(output, stack, opvar, p)
              shunt_loop(rest, o, s)
            }
          }
        }
      }
    }
  }
}

fn emptystack(output: List(Token), stack: Stack) -> List(Token) {
  case stack {
    [] -> output
    [opvar, ..rest] -> {
      let o = list.append(output, [Operator(opvar)])
      emptystack(o, rest)
    }
  }
}

fn handle_operator(
  output: List(Token),
  stack: Stack,
  variant: OperatorVariant(Int),
  precedence: Int,
) -> #(List(Token), Stack) {
  case stack {
    [] -> #(output, list.prepend(stack, variant))
    [opvar, ..rest] -> {
      case opvar {
        OParen -> #(output, list.prepend(stack, variant))
        Asterix(p) | Bar(p) | Dot(p) | QMark(p) | Plus(p) -> {
          case precedence > p {
            True -> {
              #(output, list.prepend(stack, variant))
            }
            False -> {
              let o = list.append(output, [Operator(opvar)])
              handle_operator(o, rest, variant, precedence)
            }
          }
        }
      }
    }
  }
}

// pop all operators from the stack until you find an open parentheses
// if no corresponding open parentheses is found, return an error
// on success return a tuple containing the new output and the modified stack.
fn find_oparen(
  output: List(Token),
  stack: Stack,
) -> Result(#(List(Token), Stack), String) {
  case stack {
    [] -> Error("Trailing closing bracket found in the regular expression.")
    [opval, ..rest] -> {
      case opval {
        OParen -> Ok(#(output, rest))
        _ -> {
          let out = list.append(output, [Operator(opval)])
          find_oparen(out, rest)
        }
      }
    }
  }
}
