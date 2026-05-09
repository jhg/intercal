# INTERCAL bytecode tier

A minimal bytecode-and-interpreter implementation, complementing the native AOT compilation in `src/bootstrap/intercalc.sh`. Inspired by OCaml's dual `ocamlc`/`ocamlopt` model (proposal #17 in `docs/improvement-proposals.md`).

## Status

**Educational stub.** The bytecode VM is a zsh interpreter (not assembly). It supports a deliberately small subset of INTERCAL: scalar `.N <- #M` assignments, simple `READ OUT .N`, and `GIVE UP`. Programs outside this subset fall back to compile-time errors.

The point is to demonstrate the dual-target idea, not to ship a production bytecode compiler.

## ISA

Each instruction is one line of text. Operands are space-separated.

| Op | Operands | Semantics |
|----|----------|-----------|
| `LOADI` | `dst imm` | dst = imm (16-bit) |
| `STORE` | `var slot` | spot[var] = stack[slot] |
| `LOAD` | `var` | push spot[var] |
| `IPUSH` | `imm` | push imm |
| `READOUT` | `var` | print Roman numeral of spot[var] |
| `EXIT` | | terminate program |

## Compiler: `intercalc_bc.sh`

A minimal compiler `src/bytecode/intercalc_bc.sh` that reads INTERCAL on stdin and emits bytecode on stdout. Subset only.

## Interpreter: `intercalc_vm.sh`

A minimal VM `src/bytecode/intercalc_vm.sh` that reads bytecode and executes it.

## Limitations (deliberate)

- No COME FROM, no NEXT, no STASH, no arrays, no syslib calls.
- Scalar onespot only (`.N`), no twospot or arrays.
- Output via READ OUT only (no WRITE IN).

A full bytecode tier would require ~1500 lines of asm-based VM (analogous to OCaml's ZINC machine). This stub is the educational landing.
