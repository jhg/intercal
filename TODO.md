# TODO - Working notes

## Estado actual (2026-03-22)

intercalc.sh Phase 1 bootstrap compiler: IMPLEMENTADO Y FUNCIONANDO

- Compilador shell que genera ARM64 assembly y usa `cc` como backend
- Genera binarios Mach-O arm64 nativos para macOS
- Pipeline: `intercalc.sh < source.i > binary && chmod +x binary`

## Features implementados

- [x] Lexer/tokenizer (statement splitting, label parsing, politeness tracking)
- [x] Parser (all 14 statement types)
- [x] Politeness checking (E079/E099, exemption for < 5 stmts)
- [x] Label validation (E182 duplicates, E197 range)
- [x] COME FROM resolution (E555 multiple)
- [x] Expression parser (constants, variables, mingle, select, unary ops, grouping)
- [x] Variable storage (spot, twospot, with ignore flags)
- [x] Array support (tail, hybrid, dimensioning with BY, subscript access)
- [x] GIVE UP (exit)
- [x] Assignment with overflow check (E275)
- [x] READ OUT scalar (Roman numerals)
- [x] READ OUT array (Turing Text Model output)
- [x] WRITE IN scalar (English digit names)
- [x] WRITE IN array (Turing Text Model input)
- [x] NEXT/RESUME/FORGET (with stack limit E123, E621, E632)
- [x] COME FROM (with abstain-aware redirect)
- [x] ABSTAIN/REINSTATE (by label and by gerund)
- [x] IGNORE/REMEMBER
- [x] STASH/RETRIEVE (with E436)
- [x] Probability (%N)
- [x] Native syslib (labels 1000-1550, 1900, 1910)
- [x] Error handlers (E000-E633, 16 runtime errors)
- [x] NOT/N'T initial abstain
- [x] 10/10 tests passing

## Test suite

All tests pass: `zsh tests/run_tests.sh`

- test_give_up.i - minimal exit
- test_read_out_num.i - Roman numeral output
- test_variables.i - variable assignment
- test_hello.i - Hello World (Turing Text Model)
- test_control.i - NEXT/RESUME
- test_syslib.i - syslib addition
- test_stash.i - STASH/RETRIEVE
- test_abstain.i - ABSTAIN FROM
- test_errors_rude.i - E079 politeness
- test_errors_polite.i - E099 politeness

## Proximo paso

### Fase 2: Compilador INTERCAL (self-hosted)
- [ ] Escribir syslib.i (aritmetica en INTERCAL puro)
- [ ] Escribir compilador en INTERCAL
- [ ] Bootstrapear con intercalc.sh
- [ ] Disenar mecanismo de syscalls (Label 666)

### Fase 3: GitHub workflow
- [ ] Workflow que descarga release anterior, compila nueva version, testa y publica
