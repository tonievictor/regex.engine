import gleam/list
import gleam/string

pub type OperatorVariant(prec) {
  OParen
  Asterix(prec)
  Plus(prec)
  QMark(prec)
}

pub type Token {
  CParen
  Letter(char: String)
  Operator(variant: OperatorVariant(Int))
}

pub fn tokenize(
  tokens: List(Token),
  input: String,
  index: Int,
  capacity: Int,
) -> List(Token) {
  case index == capacity {
    True -> tokens
    False -> {
      let char = string.slice(input, index, 1)
      let tok = case char {
        "*" -> Operator(Asterix(3))
        "?" -> Operator(QMark(2))
        "+" -> Operator(Plus(1))
        "(" -> Operator(OParen)
        ")" -> CParen
        _ -> Letter(char)
      }
      tokenize(list.append(tokens, [tok]), input, index + 1, capacity)
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
            Plus(_) -> to_string(rest, string.append(output, "+"))
            QMark(_) -> to_string(rest, string.append(output, "?"))
          }
        }
      }
    }
  }
}
