# rexen

[![Package Version](https://img.shields.io/hexpm/v/rexen)](https://hex.pm/packages/rexen)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/rexen/)

```sh
gleam add rexen
```
```gleam
import rexen

pub fn main() {
    let assert Ok(nfa) = rexen.new("(a?b)*")
    rexen.compute(nfa, "ab") // -> True
    rexen.compute(nfa, "ababab") // -> True
    rexen.compute(nfa, "ababa") // -> False
    rexen.compute(nfa, "a") // -> False
}
```

Further documentation can be found at <https://hexdocs.pm/rexen>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
