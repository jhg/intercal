# The compilation pipeline

This chapter is a single end-to-end walkthrough of what happens when you run:

    zsh src/bootstrap/intercalc.sh < program.i > program
    chmod +x program

The script is `src/bootstrap/intercalc.sh`. It runs seven phases, all inside one zsh process, and ends by shelling out to `cc` to link the result. The per-phase chapters that follow this one zoom in on each phase in turn; read this first to see the whole shape.

## The seven phases

                                                            +-------------------+
    .i source  ───►  read_source  ───►  tokenize  ───►  ... │  check_politeness │
                                                            │  check_labels     │
                                                            │  resolve_come_from│
                                                            │  detect_syslib    │
                                                            +---------┬---------+
                                                                      │
                                                                      ▼
                                                             codegen_program
                                                                      │
                                                                      ▼
                                              cat runtime.s syslib.s program.s | cc
                                                                      │
                                                                      ▼
                                                              binary on stdout

The list, with their entry points in `intercalc.sh`:

1. `read_source` — slurp stdin, flatten newlines and tabs to spaces, uppercase everything.
2. `tokenize` — split into statements; attach label, polite flag, negation, probability, type and body to each.
3. `scan_variables` — record which variable numbers are actually used, so we can allocate BSS space later.
4. `check_politeness` — count PLEASE usage; reject if outside [1/5, 1/3].
5. `check_labels` — reject duplicate labels; build the label→statement map.
6. `resolve_come_from` — for each `COME FROM (N)`, record the reverse edge from label `N`.
7. `detect_syslib` — scan NEXT targets; if any land in 1000–1999, flag that we need to link the syslib.
8. `codegen_program` — emit one block of assembly per statement into a growing string `$asm`.
9. Final assembly: concatenate `src/runtime/<platform>.s`, optionally `src/syslib/native/<platform>.s`, and the generated program assembly, then pipe the whole thing through `cc -x assembler - -o binary`.

Strictly speaking, steps 4–7 are separate passes over the statement list, not one phase. From a textbook standpoint they are all "semantic analysis".

## Phase 1: Read the source

`read_source` reads stdin into a single zsh string `SOURCE`. Newlines, tabs and carriage returns are collapsed to spaces. Everything is uppercased. INTERCAL is whitespace-agnostic and case-insensitive, so this simplification costs nothing and makes every later phase easier.

There is no file-level syntax to preserve. Comments don't exist. A line break has no meaning. So losing the original formatting is fine — the compiler only needs the stream of significant tokens.

## Phase 2: Tokenise

`tokenize` scans `SOURCE` character by character, accumulating until it detects the start of a new statement. Statement boundaries are defined by the verb tokens: `DO`, `PLEASE`, `DON'T`, and the combinations like `PLEASE DO` or `PLEASE DON'T`. When the tokenizer sees one of those, it closes the previous statement and starts a new one.

For each statement it extracts:

- The optional `(N)` label.
- Whether PLEASE was present (affects politeness counting).
- Whether NOT / N'T was present (statement starts abstained).
- The optional `%N` probability.
- The first keyword of the body, which determines the statement type (`ASSIGN`, `NEXT`, `RESUME`, `FORGET`, `ABSTAIN`, `REINSTATE`, `IGNORE`, `REMEMBER`, `STASH`, `RETRIEVE`, `READ_OUT`, `WRITE_IN`, `COME_FROM`, `GIVE_UP`, `UNKNOWN`).
- The raw body text, saved verbatim for the parser to work on during codegen.

The parallel arrays `stmt_label`, `stmt_polite`, `stmt_negated`, `stmt_prob`, `stmt_type`, `stmt_body` all grow by one entry per statement. `stmt_count` is the final count.

`DON'T` is its own token rather than being decomposed into `DO` + `N'T`. Getting this wrong caused a real bug earlier in the project: when `DON'T NOTE foo` was left as `DO`, `N'T`, `NOTE`, `foo`, the tokenizer merged `NOTE foo` into the previous statement's body. See the "bugs learned" memory for the full story.

For the details of tokenisation (how the scanner detects each token, what it does with the `%` probability, how it handles sparks inside the body) see [lexing-and-parsing.md](lexing-and-parsing.md).

## Phase 3: Collect used variables

`scan_variables` walks every statement body and records which `.N`, `:N`, `,N`, `;N` variable numbers appear. The result is four associative arrays `used_spot`, `used_twospot`, `used_tail`, `used_hybrid` whose keys are the numbers that actually appear in the source.

Why: the codegen phase emits one BSS symbol per used variable. A program that references `.1`, `.7` and `,3` produces three BSS symbols, not 65535×4. This keeps the output binary small and makes the generated assembly readable.

## Phase 4: Check politeness

`check_politeness` counts statements (numerator = those with `stmt_polite=1`, denominator = `stmt_count`) and verifies that `numerator * 5 >= denominator` and `numerator * 3 <= denominator`. Failure fires `die_compile 079` or `die_compile 099`, which prints `ICL079I` or `ICL099I` to stderr and exits with status 1.

This is the only compile-time error the compiler reports for a well-formed program. Every other error in the INTERCAL error catalogue is a runtime error, because INTERCAL lets you write unrecognised statements — they might be abstained and never execute.

## Phase 5: Check labels

`check_labels` builds `label_to_stmt`, a map from label number to statement index. Labels are 1–65535. Duplicates fire `die_compile 182`. The map is used later by `NEXT`, `COME FROM`, `ABSTAIN FROM (N)` and `REINSTATE (N)` codegen so they can resolve the label at compile time.

## Phase 6: Resolve COME FROM

`resolve_come_from` walks every statement whose type is `COME_FROM` and records the reverse edge: for each `COME FROM (N)`, it stores `come_from_target[N] = index_of_come_from_statement`. The codegen for statement `N` will then, after executing its own body, jump to the COME FROM statement's body instead of continuing to `N+1`.

Two COME FROMs targeting the same label would fire `die_compile 555`, but the current implementation accepts this silently; it is listed in the TODO.

## Phase 7: Detect syslib usage

`detect_syslib` scans every `NEXT` target for values in the range 1000–1999. If any are found, `needs_syslib=1`. During the final link step, the syslib native assembly (or the pure INTERCAL syslib with `--pure-syslib`) is concatenated with the runtime and the program assembly so the labels resolve.

## Phase 8: Code generation

`codegen_program` emits boilerplate: the entry point (`_main:` on macOS, `main:` on Linux), the argument-save sequence for argc/argv, the statement-flags initialisation, and the runtime-data pointers. Then it walks `stmt_body` in order, calling `codegen_statement` for each, which dispatches on `stmt_type` to one of the many `codegen_<type>` functions. Each of those emits a block of assembly that:

1. Checks the statement's abstain flag in `_stmt_flags`. If set, jumps over the body.
2. If a probability is set, rolls a random number and skips if it fails.
3. Evaluates the statement's expression(s) by walking the expression tree (`codegen_expr`, `codegen_array_ref`).
4. Performs the statement's action (store to a variable, call `_rt_write_roman`, push a NEXT frame, etc.).
5. If a COME FROM is attached to this statement's label, unconditionally jumps to its body.

Finally, `emit_data` appends the `.data` and `.bss` sections: the roman numeral table (already inside the runtime, but the per-program BSS sits in the output), the abstain-flag bit array `_stmt_flags`, and one BSS symbol per used variable.

The full per-statement walk-through lives in [code-generation.md](code-generation.md).

## Phase 9: Assemble and link

With the assembly text ready in the zsh variable `$asm`, `main` concatenates:

1. `src/runtime/<platform>.s` — the runtime.
2. `src/syslib/native/<platform>.s` if `needs_syslib=1` and `--pure-syslib` was not set.
3. The generated `$asm`.

For Linux ARM64 specifically, this combined blob is passed through a sequence of `sed` substitutions that translate macOS ARM64 assembly syntax (`_main`, `@PAGE`/`@PAGEOFF`, `svc #0x80`, `mov x16`, etc.) into Linux GNU-as syntax (`main`, `:lo12:`, `svc #0`, `mov x8`). For Linux x86-64 the codegen emits Intel syntax directly via `codegen_x86_64.sh`, which overrides every emit function.

The combined text is piped to `cc -x assembler - -o $TMPBIN`, and `$TMPBIN` is `cat`ted to stdout. The user (or the wrapper script) is expected to redirect stdout to a file and `chmod +x` it.

## Seeing each phase's output

The pipeline is opaque in its default form. Two flags make it observable:

- `INTERCAL_ASM_ONLY=1 zsh src/bootstrap/intercalc.sh < program.i` prints the generated assembly (including any Linux ARM64 sed conversion) to stdout instead of invoking `cc`.
- `tools/pipeline_dump.sh program.i` is a thin wrapper that dumps the intermediate stages.

For smaller debugging you can always add a `set -x` near the top of `intercalc.sh` and watch the phases execute.

## Next reading

- [lexing-and-parsing.md](lexing-and-parsing.md) — Phases 2 and the expression parser.
- [semantic-analysis.md](semantic-analysis.md) — Phases 4–6.
- [code-generation.md](code-generation.md) — Phase 8.
- [runtime.md](runtime.md) — what the emitted assembly calls into.
