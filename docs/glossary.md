# Glossary

This glossary collects the vocabulary a reader needs to move between the INTERCAL specification, the compiler-theory literature, and the source of this repository. Entries are grouped by domain. Cross-references use the dot notation `→ term`.

## INTERCAL symbols

- Angle-worm — `<-`. The assignment operator. Left-hand side is an lvalue, right-hand side is an expression.
- Ampersand — `&`. Unary AND of adjacent bits.
- Big money — `$`. Binary mingle. Interleaves the bits of two operands.
- Book — `V` (the letter, uppercase). Unary OR of adjacent bits.
- Double-oh-seven — `%`. Probability modifier on a statement. `%50` means execute half the time.
- Hybrid — `;`. Variable-prefix for 32-bit arrays.
- Mesh — `#`. Constant prefix. `#5` is the 16-bit constant 5.
- Rabbit-ears — `"`. Expression grouping, alternates with → spark.
- Spark — `'`. Expression grouping, alternates with → rabbit-ears.
- Spot — `.`. Variable prefix for 16-bit scalars.
- Sqiggle — `~`. Binary select. Extracts bits from the left operand where the right operand (a mask) has 1s, packs them right-justified.
- Tail — `,`. Variable prefix for 16-bit arrays.
- Two-spot — `:`. Variable prefix for 32-bit scalars.
- What — `?`. Unary XOR of adjacent bits.
- Wimpmode — a C-INTERCAL extension allowing decimal numeric I/O instead of Roman numerals and English digit names. Not implemented by this compiler.
- Wow — `!`. Reserved symbol; not used by the grammar this compiler accepts.

## INTERCAL statements

- ABSTAIN — deactivates a statement or a category of statements. Paired with → REINSTATE.
- COME FROM — the inverse of GOTO. After the labelled statement executes, control transfers to the COME FROM. Resolved at compile time.
- DO — the primary verb. Functionally identical to PLEASE DO; only politeness counting differentiates them.
- DON'T — tokenised contraction of DO + NOT. Marks a statement as abstained from the start.
- FORGET — pops N entries from the → NEXT stack without transferring control.
- GIVE UP — terminates the program. Every well-formed INTERCAL program ends with this.
- IGNORE — marks a variable as read-only. Paired with → REMEMBER.
- NEXT — pushes the current position onto the → NEXT stack and jumps to the labelled statement.
- PLEASE — the polite verb form. Contributes to the → politeness count.
- READ OUT — numeric output (Roman numerals) for scalars, → Turing Text Model output for arrays.
- REINSTATE — reverses an → ABSTAIN.
- REMEMBER — reverses an → IGNORE.
- RESUME — pops K entries from the → NEXT stack, returns to the last-popped address. `RESUME #1` is a clean subroutine return.
- RETRIEVE — pops the → stash stack, restoring the previous value of a variable.
- STASH — pushes the current value of a variable onto its per-variable stack.
- WRITE IN — numeric input (English digit names) for scalars, → Turing Text Model input for arrays.

## INTERCAL runtime concepts

- Fixpoint — the point at which a self-hosting compiler's output stabilises. See [self-hosting.md](self-hosting.md).
- Gerund — the `-ING` form of a statement verb. Used by ABSTAIN/REINSTATE to target a whole class of statements.
- Label — a parenthesised number attached to a statement, used by NEXT, COME FROM, ABSTAIN and REINSTATE to refer to that statement. Labels are unique and in the range 1–65535. Labels 1000–1999 are reserved for the → system library.
- Label 666 — the syscall extension. See [666.md](666.md).
- NEXT stack — runtime stack of return addresses, 80 slots deep. Overflow fires ICL123I.
- Politeness — the ratio of PLEASE to total statements, required to be in [1/5, 1/3].
- Stash stack — per-variable stack of previous values, grown by STASH and shrunk by RETRIEVE.
- System library (syslib) — arithmetic routines at labels 1000–1999. See [syslib.md](syslib.md).
- Turing Text Model (TTM) — the 256-position tape used for array-based text I/O. Character code is encoded as the tape-head displacement after a bit-reversal.

## Compiler-theory vocabulary

- Abstract syntax tree (AST) — a tree representation of a program's syntax, with operator nodes and leaves for literals and identifiers. Our expression parser produces an AST in parallel arrays; the statement-level representation is a flat list rather than a tree.
- Activation record — the per-call stack frame holding local variables, saved registers and return address. INTERCAL has no scope, so our "activation records" are degenerate: the NEXT stack holds only return addresses.
- Backend — the portion of the compiler responsible for emitting target-specific code. Our backend is each `codegen_<type>` function (macOS/Linux ARM64) or its override in `codegen_x86_64.sh`.
- Bootstrapping — the process of producing a self-hosting compiler without a pre-existing compiler for the same language. See [self-hosting.md](self-hosting.md).
- BSS — the "Block Started by Symbol" section of an executable, holding zero-initialised data. Used here for statement-flag bytes, scalar variables, array pointers, the NEXT stack, etc.
- Bytecode — a fabricated machine code for a virtual machine, used as an intermediate representation in some compilers. We do not use bytecode; we emit target assembly directly.
- Calling convention — the contract between caller and callee about register usage, argument passing, and preservation. ARM64 macOS and Linux share the AAPCS64 convention; Linux x86-64 uses System V AMD64.
- Codegen — short for code generation, the phase that produces target code from the parsed program.
- Cross-compiler — a compiler running on platform A that produces binaries for platform B. Our compiler is *not* a cross-compiler today; it targets only the platform it runs on.
- Differential testing — a testing technique that runs the same input through two independent implementations and compares their outputs. We use it between pure and native syslib (see [testing-and-workflow.md](testing-and-workflow.md)).
- Fixpoint — see above under INTERCAL runtime.
- Front end — the portion of the compiler responsible for reading the source language: lexer, parser, semantic analysis. Our front end is `tokenize`, `parse_expr`, and the three check routines.
- Intermediate representation (IR) — a language-neutral representation between source and target. Our compiler has no IR.
- Lexer — also called scanner or tokeniser. Splits the source into tokens. Ours is `tokenize()`.
- Linker — the tool that combines object files into an executable. We invoke it via `cc -x assembler -`, which uses the system `cc` as a driver for `ld`.
- Mach-O — the executable format used on Apple platforms. Our macOS target produces Mach-O binaries.
- Middle end — the portion of a compiler that operates on an → intermediate representation for optimisation purposes. We have no middle end.
- Parser — reads the token stream and produces an AST or equivalent. Ours is `parse_expr()` for expressions; statement-level parsing is inlined in `tokenize`.
- RIP-relative addressing — an x86-64 instruction-addressing mode where displacements are relative to the instruction pointer. Used to produce position-independent code without a PLT.
- Runtime — the code that is present in every produced binary to implement language-level operations the compiler does not inline. See [runtime.md](runtime.md).
- Scanner — synonym for lexer.
- Self-hosting — a compiler that can compile its own source. See [self-hosting.md](self-hosting.md).
- Semantic analysis — checks that depend on meaning rather than syntax alone. Ours are politeness, label uniqueness, COME FROM resolution.
- Symbol table — the data structure that maps names in the source to their properties. Ours are `label_to_stmt`, `used_spot`, `used_twospot`, `used_tail`, `used_hybrid`.
- System V AMD64 ABI — the calling convention on Linux x86-64 and most other Unix-like x86-64 systems. Arguments in rdi, rsi, rdx, rcx, r8, r9.
- Tokenisation — the act of splitting source text into tokens.
- Translation unit — a source file that the compiler compiles in isolation. In INTERCAL, the whole program is a single translation unit; there is no preprocessor or `#include`.

## Project-specific vocabulary

- Chispa primigenea — the primordial spark, our term for the shell-bootstrap compiler `intercalc.sh`. Spanish phrase chosen for poetic effect.
- Generation — one compile of the self-hosted compiler by an older self-hosted compiler. See `bootstrap.sh` and [self-hosting.md](self-hosting.md).
- MVP — minimum viable product. The self-hosted template-dispatch compiler `compiler.i` is the MVP; `stage3.i` is evolving past it.
- Primordial spark — English rendering of → chispa primigenea.
- Template — a pre-generated assembly file under `src/compiler/templates/<platform>/<testname>.s`. Used by the MVP's content-hash dispatch.
- Templatised — of the MVP: the fact that its "compilation" is a lookup and not a real phase.
