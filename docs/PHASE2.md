# Phase 2: Self-Hosted INTERCAL Compiler

Working document for building compiler.i - the INTERCAL compiler written in INTERCAL.

## Architecture

compiler.i (at src/compiler/compiler.i) reads source via Label 666 (argv -> open -> read), generates ARM64 assembly to stdout via Turing Text Model. The wrapper script (intercal) concatenates src/runtime/{platform}.s + src/syslib/native/{platform}.s + compiler output and pipes to cc.

## Status

Stage 1: COMPLETE - I/O round-trip (read file, echo to stdout)
Stage 2: COMPLETE - Read source, copy to ,10, uppercase, output length as Roman
Stage 3: NOT STARTED - Lexer (count statements by scanning for DO/PLEASE)
Stage 4: NOT STARTED - Parser (classify statements, expression trees)
Stage 5: NOT STARTED - Semantics (politeness, labels, COME FROM)
Stage 6: NOT STARTED - Minimal codegen (GIVE UP only)
Stage 7: NOT STARTED - Incremental codegen (all statement types)
Stage 8: NOT STARTED - Full compiler + fixpoint test

## Module Map (labels 100-849)

| Labels | Module | Purpose |
|--------|--------|---------|
| 100-149 | Main | Read source file, orchestrate phases, flush output |
| 150-199 | Input | Copy ,65535 to ,10, uppercase conversion |
| 200-299 | Lexer | Scan for DO/PLEASE keywords, count/record statements |
| 300-399 | Parser | Classify statements, parse expressions into tree |
| 400-449 | Semantics | Politeness check, label validation, COME FROM resolution |
| 450-499 | Codegen control | Main codegen loop dispatching by statement type |
| 500-549 | Codegen expressions | Walk expression tree, emit assembly per node |
| 550-599 | Codegen statements | Emit assembly for each statement type |
| 600-649 | Codegen data | Emit BSS variables, _stmt_flags, _main entry |
| 700-749 | TTM output | Emit chars to stdout: bit reversal, tape tracking, buffer, flush |
| 750-799 | Utilities | Character compare, itoa, keyword matching |
| 800-849 | Errors | Emit compile-time errors to stderr |

## Data Structures

| Variable | Type | Purpose |
|----------|------|---------|
| ,10 | tail 60000 | Source characters (uppercased) |
| .50 | spot | Source length |
| ,11-,18 | tail 1000 each | Statement parallel arrays |
| .51 | spot | Statement count |
| ,19 | tail 1000 | Label-to-statement mapping |
| ,20-,23 | tail 5000 each | Expression tree nodes |
| ;20 | hybrid 5000 | Expression values (32-bit) |
| .52 | spot | Next free expression node |
| ,30 | tail 60000 | TTM output buffer |
| .60 | spot | Output buffer position |
| .71 | spot | TTM output tape head position |
| ,31-,34 | tail 200 each | Used variable numbers |
| .61-.64 | spot | Variable counts |
| ,35-,36 | tail 100 each | Temporary string buffers |

## INTERCAL Programming Patterns (learned during development)

These are patterns we discovered while implementing syslib.i and compiler.i. They are essential for writing correct INTERCAL.

### Comments

Use `DON'T NOTE ...` (= `DO NOT NOTE ...`). This creates a negated UNKNOWN statement that is skipped at runtime. Never use `PLEASE NOTE` (it would be an executable UNKNOWN statement that triggers E000).

### COME FROM loop

```intercal
(200) DO COME FROM (219)
      ... loop body ...
(219) DO .99 <- #0
```

Statement labeled (219) executes, then COME FROM redirects to (200). To break: `DO ABSTAIN FROM (200)`.

### Conditional branch (two-way)

Convert a 0/1 value to 1/2 for computed RESUME:

```intercal
DON'T NOTE Convert .22 (0 or 1) to .23 (1 or 2)
DO :20 <- '.22 $ #1'
DO .23 <- '?:20 ~ #3'
DON'T NOTE Branch: .23=1 goes to RESUME path 1, .23=2 to path 2
DO (LABEL_A) NEXT
DO (LABEL_B) NEXT
DO RESUME .23
```

### Syslib calling convention

Always STASH variables before calling syslib:
```intercal
DO STASH .1 .2 .3 .4
DO .1 <- value1
DO .2 <- value2
DO (1000) NEXT
DO .99 <- .3          DON'T NOTE save result
DO RETRIEVE .1 .2 .3 .4
```

### NEXT stack discipline

- Max 79 entries. The 80th causes E123.
- FORGET #1 at top of loop iterations to prevent accumulation.
- Every NEXT inside a branch pattern needs a corresponding FORGET on each path.

### Expression grouping

- Sparks `'...'` and rabbit-ears `"..."` must alternate nesting.
- Never nest same type: `'...'...'...'` is WRONG.
- Break complex expressions into steps using intermediate twospot variables:
  ```intercal
  DON'T NOTE Instead of: .17 <- '"?:13" ~ #1'
  DON'T NOTE Do this:
  DO :14 <- '?:13'
  DO .17 <- ':14 ~ #1'
  ```

### Zero test

```intercal
DON'T NOTE .22 = 0 if .X is zero, 1 if nonzero
DO .22 <- "'.X ~ .X' ~ #1"
```

### Uppercase conversion (ASCII)

Characters 97-122 (a-z) subtract 32 to become 65-90 (A-Z):
```intercal
DO STASH .1 .2 .3 .4
DO .1 <- .21
DO .2 <- #97
DO (1010) NEXT
DO .1 <- .3
DO .2 <- #65510
DO (1009) NEXT
DON'T NOTE .4 = 1 if lowercase (no overflow), 2 if not (overflow)
```

## Stage Descriptions

### Stage 1 (COMPLETE): I/O round-trip
Read source file via Label 666 (argv -> open -> read), write to stdout (write -> close). Proves the I/O pipeline works.

### Stage 2 (COMPLETE): Copy + uppercase + length
Copy ,65535 to ,10 with ASCII uppercasing. Output source length as Roman numeral. Proves array operations and syslib calls work.

### Stage 3: Lexer
Scan ,10 for statement keywords (DO, PLEASE, DON'T). Count statements in .51. Record boundaries in parallel arrays ,11-,12. Output statement count.

### Stage 4: Parser
Classify each statement by type. Parse expression trees into ,20-,23. Extract labels, negation, probability.

### Stage 5: Semantics
Check politeness ratio (E079/E099). Validate labels (E182/E197). Resolve COME FROM (E555). Detect syslib usage.

### Stage 6: Minimal codegen
Emit assembly for GIVE UP only: _main entry, exit syscall, BSS section. Test by assembling with runtime.s.

### Stage 7: Incremental codegen
Add statement types one at a time: ASSIGN, READ OUT, NEXT/RESUME, FORGET, COME FROM, ABSTAIN, IGNORE, STASH, RETRIEVE, arrays, WRITE IN. Test each against intercalc.sh output.

### Stage 8: Fixpoint
Three-generation self-compilation test. Generation 2 output must equal generation 3 output.

## Codegen Reference

The INTERCAL compiler must emit the SAME assembly patterns as intercalc.sh. For each statement type, look at the codegen_* functions in intercalc.sh to see what assembly to generate. The self-hosted compiler follows the bootstrap compiler exactly.
