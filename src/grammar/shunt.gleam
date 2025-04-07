// this module is an implementation of the Shunting-Yard Algorithm 
// SYA is used to convert the grammar from infix notation to postfix notation

import gleam/list
import grammar/lexer.{
  type OperatorVariant, type Token, Asterix, CParen, Letter, OParen, Operator,
  Plus, QMark,
}

pub type Stack =
  List(OperatorVariant(Int))

pub fn shunt(
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
        Letter(_) -> shunt(rest, list.append(output, [tok]), stack)
        CParen -> {
          case find_oparen(output, stack) {
            Ok(#(o, s)) -> {
              shunt(rest, o, s)
            }
            Error(err) -> Error(err)
          }
        }
        Operator(opvar) -> {
          case opvar {
            OParen -> shunt(rest, output, list.prepend(stack, opvar))
            Asterix(p) | Plus(p) | QMark(p) -> {
              let #(o, s) = handle_operator(output, stack, opvar, p)
              shunt(rest, o, s)
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
        Asterix(p) | Plus(p) | QMark(p) -> {
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
    [] -> Error("Could not find a corresponding opening bracket on the stack")
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
