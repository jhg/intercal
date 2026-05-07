# Appendix: exercise hints

Hints — not full solutions — for the exercises that close most chapters. The hints are deliberately short. They unblock a stuck reader without short-circuiting the act of working through the problem.

If a chapter's exercises are not listed below, the exercises are direct enough that hints would be redundant.

## intercal-primer.md

1. 4/17 ≈ 23.5%, comfortably inside [20%, 33.3%]. The lower bound becomes binding when total = 20 (4/20 = 20%). Any further shrinkage breaks it.
2. The smallest STASH/RETRIEVE program is two statements after dimensioning a politeness count. Swapping fires `ICL436I RETRIEVE WITHOUT STASH`.
3. `#5` is `0b0000000000000101`. Unary AND XORs each bit with its right neighbour. Bit 0 is `1 & 0 = 0`. Bit 1 is `0 & 1 = 0`. Bit 2 is `1 & 0 = 0`. The rest are `0 & 0 = 0`. Result: 0. Surprised? That is the lesson.
4. The idiom converts a 0/1 value into 1/2, pushes two NEXT targets, then `RESUME`s with the 1/2 variable. `RESUME #1` returns to the most recent target; `RESUME #2` skips one.
5. Alternatives: `DO .99 <- #0` is nominally a no-op but actually wastes politeness count. Inserting a labelled statement and then `ABSTAIN`ing it is verbose. `DON'T NOTE` is shortest and idiomatically read as a comment.

## pipeline.md

1. The codegen prologue is everything before `_stmt_0_start`. `codegen_give_up` produces the exit syscall sequence (`mov x0, #0; mov x16, #1; svc #0x80`). Everything else is runtime.
2. `SOURCE` is materialised once. The lexer splits it incrementally without making copies — the `stmt_body` entries are slices.
3. Swapping politeness and label checks would mean a duplicate-label program might silently fail the politeness check first. Functional difference: zero, because both are fatal.
4. `DO (1000) NEXT` flips `needs_syslib` to 1. Any label in [1000, 1999] does.
5. Putting the program first means its `_main` entry is followed by the runtime symbols. The linker accepts this — symbols are resolved by name, not order — but a sharper symbol search misses for the entry point. In practice the binary still works.

## lexing-and-parsing.md

1. Politeness is identical because both forms are negated; only the verb tokens differ. The runtime difference is that `DON'T` is one token and `DO NOT` is two, but both produce a negated statement.
2. The keyword list is in `tokenize()`. None of them is a prefix of another in the current grammar (`DO` is not a prefix of any longer keyword; `DON'T` is detected before `DO`).
3. The tree has 5 nodes: NODE_VAR for `.1`, NODE_CONST for `#5`, NODE_CONST for `#3`, NODE_SELECT for the `~`, NODE_MINGLE for the `$`. The `~` is the parent of the two constants.
4. The two operators consume different token characters (`$` vs `~`), so the parser can dispatch on the next token without lookahead.
5. `'a + 'b''` (or any spark inside spark) is accepted by the parser. At runtime the misnested expression fires ICL017I.

## semantic-analysis.md

1. For 7 statements: 2 ≤ PLEASE ≤ 2. For 12: 3 ≤ PLEASE ≤ 4. For 100: 20 ≤ PLEASE ≤ 33.
2. The compiler's `label_to_stmt` is bounded by the labels actually in source, so it would not need to change. The runtime's per-label tables (none, currently — labels are resolved at compile time) similarly would not change. The reduction would only affect the compile-time bounds check on label values.
3. Two `COME FROM (100)` statements in the same program. The current behaviour is that the second silently overwrites the first; the spec says `ICL555I MULTIPLE COME FROMS`.
4. Reading an unwritten variable yields 0 (the BSS initial value). If we only recorded written variables, the codegen would not emit a BSS slot, and the read would dereference an undefined symbol — link error.
5. For: catches a class of bugs at compile time. Against: `RESUME` takes an expression that may not be statically computable. The compile-time check would flag `RESUME #0` but not `RESUME .1` where `.1` happens to be 0.

## code-generation.md

1. The abstain check is 4 instructions per statement (`adrp`, `add`, `ldrb`, `cbnz`). On 1000 statements that is 4000 instructions. If the average statement body is 10 instructions, the overhead is ~30%.
2. `DO .1 <- '#5 $ #3'` produces one `bl _rt_mingle`. A constant-folding pass would compute the result at compile time and emit `mov w0, #N` where N is the precomputed mingle of 5 and 3.
3. Array element assignment skips the ignore check because arrays do not have an ignore flag in the current implementation. This is a feature gap, not a bug — the spec allows IGNORE on arrays but our compiler does not yet.
4. The previous allocation is leaked. The runtime never calls `munmap`. The OS reclaims at process exit.
5. Refactoring would require either a base-architecture-agnostic emit primitive or a templating layer that fills in per-architecture instruction names. Neither is large; the question is whether the duplication is bothersome enough to justify the abstraction.

## runtime.md

1. `_rt_write_roman` for `w0 = 0` walks the Roman numeral table, finds nothing it can subtract, and writes nothing. The output is empty. Acceptable because Roman numerals do not represent zero.
2. With 128 entries, every character would map to two possible ASCII codes. The bit-reversal scheme requires a power-of-two tape size that is at least 256 to round-trip every byte.
3. Yes. `,1` is dimensioned to 3, then element 1 is 72 (ASCII H). `READ OUT ,1` walks the array; the first delta moves the head from 0 to 248 (= -72 mod 256), bit-reversed to ASCII H = 72. Print "H".
4. The runtime BSS reservation `_next_stack` would change from 80×8 to 1024×8. The codegen's overflow check `cmp w0, #79` would change to `cmp w0, #1023`. The error message would still fire ICL123I.
5. The C program has to use the same ABI: AAPCS64 on ARM64, System V AMD64 on x86-64. Calling our `_rt_*` functions from C is straightforward — the runtime functions follow the standard ABI.
6. A program that dimensions an array repeatedly inside a loop would leak memory faster than the OS reclaims it (until the program ends).

## syslib.md

1. The native binary is ~40 KB; the pure-syslib binary is ~1.3 MB. The factor is 33×.
2. Three statements: STASH the variables, NEXT to label 1010 (subtract), then NEXT to label 1000 (add) and compare to `.1`.
3. The 330× factor matches what you measure: a program that takes 0.09s with native takes ~30s with pure.
4. Label 1900 invokes Label 666 syscall 9. Native: one syscall. Pure: ~10 INTERCAL statements that ultimately invoke the same syscall.
5. The pure syslib needs the routine added in INTERCAL. The native syslib needs the matching assembly per platform. The compiler's `detect_syslib` does not need changes — it already triggers on any 1000-1999 label.

## self-hosting.md

1. `bootstrap.sh` greps `compiler.i` for `codegen|_stmt_|.section`. If none of those appear, it skips. The MVP `compiler.i` does not include them, so `bootstrap.sh` exits cleanly without doing the bootstrap.
2. gen1 and gen2 can differ in (e.g.) register allocation; gen2 and gen3 cannot, because the compiler is now its own input and any compiler-determined difference would have shown up at gen2. Example where gen1 = gen2 = gen3: a compiler that generates byte-identical output regardless of which compiler compiled it. Possible only if the bootstrap and the self-hosted are byte-equivalent — which is exceptional.
3. To distinguish DO from PLEASE DO, stage3 needs to read the verb word and branch. Smallest extension: ~30 lines of INTERCAL to scan past whitespace and compare the next 6 characters.
4. Yes — Python is on every CI runner. The bootstrap would become Python instead of zsh; CI matrix and dependencies remain identical.
5. No. The fixpoint test cares about the compiler reproducing itself, not about which syslib it links. Adding `--pure-syslib` would multiply compile time by 330× without gaining anything.

## platforms.md

1. macOS uses carry-flag conditionals because the underlying syscall ABI sets the carry on error. Linux returns negative values directly. Both predate AAPCS standardisation.
2. `0x1002` appears in the `mmap` syscall flags. The `sed` is conservative; it would not match inside a comment because the pattern is anchored on the operand position.
3. Windows ARM64 should use a fresh codegen backend — the COFF format and Windows calling convention are too different for a `sed` translation.
4. Yes. AT&T syntax requires every operand prefixed with `%` and source-first ordering; the codegen output would have to be rewritten line by line.
5. About 60% slowdown is x86-64 emulation on ARM64; about 40% is Docker overhead. Measure independently by running the tests inside an x86-64 container on a real x86-64 machine.

## testing-and-workflow.md

1. The flags are `--filter`, `--verbose`, `--keep`, `--no-color`, `--platform`. `--filter` is for iterating on a single failing test; `--verbose` shows `cc` stderr for assembly errors; `--keep` preserves failed-test artifacts in `/tmp/intercal_failures` for post-mortem; `--no-color` is for CI logs; `--platform` overrides platform detection for cross-builds.
2. A test where the RHS is large and the variable is ignored: if the codegen reordered the checks, either the ignored write would still trigger an overflow error, or the overflow check would silently succeed because the ignore came first.
3. A program exercising mingle and select with non-trivial bit patterns. Catches divergence in operator implementation that the existing add/sub/divide tests don't.
4. For: workflow edits do not affect compiled program behaviour. Against: a broken workflow has surfaced subtle bugs (e.g. a CI yaml typo that masks failures).
5. The slowdown ratio measures cumulative overhead. Subtract Docker startup (~3s) and you have the per-test x86-64 emulation cost.

## walkthrough-hello.md

1. Maximum: 5 PLEASEs is 29.4% (under 33.3%). 6 is 35.3% (over). So 5 is the maximum; one more flip is fine.
2. ~12 instructions per statement (4 abstain check + 5 array element handling + 3 type/range), times 17 = ~200 instructions. Plus 20+ for the array dimensioning.
3. The politeness ratio drops from 4/17 to 3/17 = 17.6%, below 20%. Compiler emits `ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE`.
4. Hello world does not call any syslib labels (1000-1999). `--pure-syslib` linking is conditional on syslib usage.
5. Reducing dimension to 13: `READ OUT ,1` would print 13 characters instead of 14, missing the last `!`. Increasing to 30: the unset elements default to zero, which the TTM tape interprets as "no head movement" and emits the same character repeatedly (or near-zero noise).

## debugging.md

1. ICL079I tests fail because the bound moved. Reproduce: change bounds, run tests, check `politeness_*` failures.
2. 80 NEXTs without intervening RESUMEs trigger ICL123I (the 80th attempt fails).
3. Multiplication tests fail first — `_rt_mingle` is on every multiplication's hot path. ~15 of the 25 tests use mingle.
4. Use `git log --oneline | grep -i 'open\|write'` to find candidate commits. Test each with `git bisect run`.
5. Yes — `stage3.i` may have a politeness or label issue caught by the linter.

## anatomy-of-a-binary.md

1. The diff appears in a single `.data` byte — the constant value at the changed offset.
2. Hello world calls `_rt_write_roman` zero times (it uses `_rt_read_out_array` for character output). `tests/test_read_out_num.i` calls it once per `READ OUT` of a scalar.
3. 1000-statement program: ~50 KB code, 1 KB BSS for stmt_flags, 500 bytes per scalar. Roughly 60 KB total.
4. `strip` removes the symbol table, saving roughly half the size for small binaries. The remaining content is the actual code and data.
5. Hello world makes ~17 syscalls (one `write` per character emitted, plus the `exit`).

## label-666-intro.md

1. Set `.1=5`, `(666) NEXT`, READ OUT `.3`. Done.
2. Open the file (syscall 1), loop 10 times reading 1 byte each (syscall 2), READ OUT each byte from `,65535 SUB #1`, close (syscall 4).
3. `,65535` is overwritten by every Label 666 read. A program that uses it for its own purposes would have its data clobbered on the next syscall.
4. `.2 = 0` returns a uniform 16-bit random number. The runtime treats it as "no range limit specified".
5. The MVP uses syscalls 6 (argv), 1 (open), 2 (read), 4 (close), 3 (write).

## lexer-theory.md

1. Two states: a "start" state and a "consuming digits" state. The transition between them is the `#` character; the transition out is whitespace or a non-digit.
2. Adding NOT and N'T as separate tokens after DO requires three more states: one for "after DO", one for "consuming N", one for emitting either NOT (after `OT`) or N'T (after `'T`).
3. The lexer already uppercases everything, so a lowercase variant requires zero changes.
4. SUB is a body-level keyword. Detecting it during expression parsing rather than lexing means the parser can resolve subscripts in their grammatical context. Moving it to the lexer would force the lexer to know which surrounding tokens make `SUB` a keyword vs an identifier — which it cannot, since INTERCAL has no identifiers.
5. Collapsing the DO/DON'T branch into a single state machine is straightforward: read the verb-token, then check for `'T` immediately after.

## parser-theory.md

1. Each non-terminal's FIRST set: `expr` starts with primary's FIRST. `primary` starts with `#`, prefix character, unary char, or grouping char. No overlap.
2. Add `@` as a binary_op alternative. The parser changes by adding `@` to the binary-op test in the parse loop.
3. Five sparks/rabbit-ears deep: `'a $ "b $ 'c $ "d $ 'e' "' "' "' "'`. An LR parser would consume tokens left-to-right and reduce on each grouping pair; recursion depth in our parser is exactly the nesting depth.
4. Unbalanced sparks: error message could be `expected ' but found ; line 5`. Variable prefix without number: `expected number after . at offset 12`.
5. Sacrifices: pointer indirection is harder to follow; debugger inspection requires array-index lookup; the layout cannot grow more children per node without coordinated array growth.

## calling-conventions.md

1. Two register moves: `_spot_1` address into `x0`, then `ldr w0` to fetch the value. One stack save: the `stp x29, x30` in `_rt_write_roman`'s prologue.
2. `stp x19, x30, [sp, #-16]!` then `ldp x19, x30, [sp], #16; ret`.
3. `r10` is touched by syscalls (replaces `rcx`). The runtime saves and restores it where needed.
4. Every syscall wrapper saves `rcx` and `r11` because `syscall` clobbers them. Look for `push rcx; push r11` patterns.
5. Some ARM64 instructions (`stp`, `ldp`) operate on aligned 16-byte pairs. 8-byte alignment would slow them down or rule them out.

## executables-and-linking.md

1. `file ./program` prints the format and architecture. Match against the table in the chapter.
2. Mach-O hello world: ~25 `_rt_*` symbols, 17 `_stmt_N_*` pairs (34 symbols).
3. On-disk size is smaller than the section table sums because BSS is not stored on disk.
4. Without ICL633I, the program executes past the last instruction into uninitialised memory. SIGILL or similar.
5. The implicit default section is `.text` for instructions and `.data` for `.ascii`. A program with neither directive would land in whatever section the assembler defaults to at the start of the file — usually `.text`.

## middle-end-and-optimisation.md

1. Without `--pure-syslib` the cost is dominated by the codegen of user statements; with it, by tokenising and processing 9000 lines of syslib INTERCAL.
2. Three consecutive statements like `mov w0, #5; str w0, [_spot_1]; ldr w0, [_spot_1]` can collapse to `mov w0, #5; str w0, [_spot_1]`.
3. 100 statements × 4 abstain instructions × possibly 2 cycles = 800 cycles saved. Negligible on modern out-of-order hardware.
4. ~10 opcodes: assign, mingle, select, unary_op (×3), call, branch, label, return.
5. Few. Most INTERCAL programs have <10 control-flow joins.

If you find yourself stuck on an exercise not listed here, drop a question into `TODO.md` or open an issue.
