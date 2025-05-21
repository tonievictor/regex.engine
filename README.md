# rexen

[![Package Version](https://img.shields.io/hexpm/v/rexen)](https://hex.pm/packages/rexen)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/rexen/)

```sh
gleam add rexen
```
```gleam
import rexen

pub fn main() {
    let assert Ok(nfa) = rexen.new("(ab)*")
    rexen.compute(nfa, "ab") // -> True
    rexen.compute(nfa, "ababab") // -> True
    rexen.compute(nfa, "ababa") // -> False
    rexen.compute(nfa, "a") // -> False
}
```

## Features
Rexen supports a core set of regular expression operations, including:
| Operator | Description | Expression | Matches |
| -------- | ----------- | ---------- | ------- |
| `*` | Zero or more of the preceding character or group of characters | `a*` | "", "a", "aa" "aaa" |
| `+` | One or more of the preceding character or group of characters | `a+` | "a", "aa", "aaa" |
| `?` | Zero or one of the preceding character or group of characters | `a?` | "", "a" |
| `\|` | Matches either the expression before or after the operator | `a\|b` | "a", "b" |

> Note: Concatenation is implicit in rexen. ie the expression `abc` matches `a`
> followed by `b` and `c` - "abc"

Further documentation can be found at <https://hexdocs.pm/rexen>.

## Development

```sh
gleam test  # Run the tests
```
