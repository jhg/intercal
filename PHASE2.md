# Phase 2: Self-Hosted INTERCAL Compiler

Working document for building compiler.i - the INTERCAL compiler written in INTERCAL.

## Architecture

compiler.i reads source via Label 666 (argv -> open -> read), generates ARM64 assembly to stdout via Turing Text Model. The wrapper script (intercal) concatenates runtime.s + syslib_native.s + compiler output and pipes to cc.

## Status

Stage 1: Not started
Stage 2: Not started
Stage 3: Not started
Stage 4: Not started
Stage 5: Not started
Stage 6: Not started
Stage 7: Not started
Stage 8: Not started

## Module Map (labels 100-849)

| Labels | Module | Purpose |
|--------|--------|---------|
| 100-149 | Main | Read source file, orchestrate phases, flush output |
| 150-199 | Input | Read file via Label 666 into array ,10 |
| 200-299 | Lexer | Tokenize: split on DO/PLEASE, extract labels, negation, probability |
| 300-399 | Parser | Classify statements, parse expressions into tree (,20-,23/;20) |
| 400-449 | Semantics | Politeness check, label validation, COME FROM resolution |
| 450-499 | Codegen control | Main loop dispatching by statement type |
| 500-549 | Codegen expressions | Walk expression tree, emit assembly per node |
| 550-599 | Codegen statements | Emit assembly for each statement type |
| 600-649 | Codegen data | Emit BSS variables, _stmt_flags, _main entry |
| 700-749 | TTM output | Emit chars to stdout: bit reversal, tape tracking, buffer, flush |
| 750-799 | Utilities | Character compare, itoa, keyword matching |
| 800-849 | Errors | Emit compile-time errors to stderr |

## Data Structures

| Variable | Type | Purpose |
|----------|------|---------|
| ,10 | tail 60000 | Source characters |
| .50 | spot | Source length |
| ,11-,18 | tail 1000 each | Statement parallel arrays (start, len, label, type, polite, negated, prob, next_target) |
| .51 | spot | Statement count |
| ,19 | tail 1000 | Label-to-statement mapping |
| ,20-,23 | tail 5000 each | Expression tree (type, left, right, width) |
| ;20 | hybrid 5000 | Expression values (32-bit) |
| .52 | spot | Next free expression node |
| ,30 | tail 60000 | TTM output buffer |
| .60 | spot | Output buffer position |
| .71 | spot | TTM output tape head position |
| ,31-,34 | tail 200 each | Used variable numbers (spot, twospot, tail, hybrid) |
| .61-.64 | spot | Variable counts |
| ,35-,36 | tail 100 each | Temporary string buffers |

## TTM Output Engine (critical)

Every assembly character is emitted via TTM. The engine at labels 700-749 must:

1. Label 700 (emit char): .70 = ASCII code -> compute TTM offset -> store in ,30
2. Label 705 (emit string from array): ,35 = chars, .72 = length -> loop calling 700
3. Label 710 (emit decimal): .73 = number -> convert to ASCII digits -> emit each
4. Label 715 (flush): dimension ,30 to .60 elements, READ OUT ,30, reset .60
5. Label 720 (bit reversal): .70 -> reversed .70

## Codegen Reference

The INTERCAL compiler must emit the SAME assembly patterns as intercalc.sh. For each statement type, look at the codegen_* functions in intercalc.sh to see what assembly to generate.

## Stages

Stage 1: I/O round-trip (read source file, echo to stdout)
Stage 2: Lexer (tokenize, report statement count)
Stage 3: Parser (classify + expression trees)
Stage 4: Semantics (politeness, labels, COME FROM)
Stage 5: Minimal codegen (GIVE UP only)
Stage 6: Incremental statement codegen (one type at a time)
Stage 7: Full compiler (all types, all tests pass)
Stage 8: Fixpoint (3 generations, asm2 == asm3)
