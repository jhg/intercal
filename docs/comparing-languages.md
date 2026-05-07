# How a C or Lisp compiler would differ

Most readers approaching this repository have built or studied a compiler for some other language: C, Java, Python, Lisp, perhaps a small functional language for a course. This chapter sets our INTERCAL implementation alongside what those readers expect, phase by phase, so the design choices we have made become legible by contrast.

The two reference points are deliberately chosen:

- **C** represents an imperative, statically typed, machine-oriented language. Its compiler design is the canonical case in most textbooks.
- **Lisp** represents a functional, dynamically typed, expression-oriented language. Its compiler design forces a different set of decisions.

Both are well documented elsewhere; this chapter does not try to teach either. It catalogues the differences from our implementation and explains why we chose what we chose.

## Lexing

A C lexer has to handle:

- String literals with escape sequences, multi-line continuations, and (historically) trigraphs.
- Numeric literals in three bases (decimal, octal, hexadecimal) plus floating-point.
- A preprocessor that runs before lexing proper, expanding `#include`, `#define`, and conditional compilation.
- Wide characters and Unicode source identifiers (in modern C).
- The famous lexer hack for distinguishing `T * x` (multiplication) from `T * x` (declaring `x` as pointer to `T`), which requires the lexer to know which identifiers are typedef names.

A Lisp lexer is by contrast almost trivial:

- Parentheses, atoms, numbers. That is most of it.
- Quoted strings exist but the syntax is uniform.
- The reader macro system lets the user extend the lexer at runtime, which sounds dramatic but in practice only adds a handful of cases.

Our INTERCAL lexer falls between the two, closer to Lisp:

- No string literals. Constants are decimal integers only.
- No preprocessor. No conditional compilation. No includes.
- One lexer hack: `DON'T` must be one token, not `DO` + `N'T`. This is dispatched by a single peek-ahead branch.
- Whitespace is collapsed during reading; case is folded.

The C lexer's cost (the typedef hack, the preprocessor's macro expansion, the float-literal grammar) does not apply to us. The Lisp lexer's flexibility (reader macros) does not apply either, because we do not need it. We get a lexer that is simpler than a C lexer and more case-driven than a Lisp lexer, but architecturally closer to either than to a hypothetical "modern" lexer with Unicode and string interpolation.

## Parsing

C grammar has notorious ambiguities:

- Operator precedence. `*p++` parses as `*(p++)`, not `(*p)++`. Sixteen levels of precedence.
- The dangling-else problem: in `if (a) if (b) c; else d;`, which `if` does the `else` belong to?
- Function pointer declarations whose syntax mirrors the call form.
- Compound literals.
- The previously-mentioned typedef ambiguity.

A C parser is typically LALR(1) (yacc/bison) or hand-written recursive descent with substantial lookahead. Either way it is hundreds of productions and several thousand lines.

Lisp's parser, in turn, is a `read` loop:

    read():
      consume whitespace
      if next is '(': read list of read() until matching ')'
      else if next is digit: read number
      else: read symbol

That is the whole parser. There is no precedence to resolve, because every expression is already explicitly grouped by parentheses. There is no dangling else, because there is no `else`.

INTERCAL's parser sits with Lisp's: we have no precedence either, because every expression is explicitly grouped by sparks `'` or rabbit-ears `"`. The recursive-descent parser has fifteen productions and runs in ~190 lines. Like Lisp, our grammar is LL(1); like Lisp, our parser corresponds line-for-line with the grammar.

The cost we pay for this simplicity is the same cost Lisp pays: programmers have to type more grouping characters. INTERCAL programmers also have to alternate the two grouping types, which is a constraint Lisp does not impose.

## Type checking

C's type system is the main reason a C compiler has a substantial semantic-analysis phase:

- Implicit type promotions: `int + char` produces `int`, with the `char` widened.
- Pointer arithmetic: `p + 1` where `p` is `T *` advances by `sizeof(T)` bytes.
- Function-call type checking: arguments must match parameter types, or be promotable to them.
- `const`, `volatile`, `restrict` qualifiers.
- Aggregate types: structs, unions, arrays.

Lisp at the standard end of the spectrum has no compile-time types at all. Every value carries a runtime tag, and operators dispatch on that tag. The compiler's "type checking" reduces to "is this a syntactically valid Lisp expression", which the parser has already answered.

INTERCAL has four types: onespot (16-bit), twospot (32-bit), tail array (16-bit elements), hybrid array (32-bit elements). They are syntactically identifiable by the variable prefix. Type checking reduces to:

- Is the assignment target's prefix consistent with the LHS expression's width?
- Is the array subscript count correct for the array's dimensionality?
- Is the value being stored within the target's range (16-bit slots reject values > 65535)?

The first is a compile-time check buried in `codegen_assign`. The second is a runtime check (we do not track array dimensionality through expressions statically). The third is a runtime overflow check that fires ICL275I.

So our type system sits between C's and Lisp's: more structure than Lisp but vastly less than C. The compile-time checking is correspondingly modest.

## Intermediate representation

A modern C compiler has a multi-stage IR pipeline:

- After parsing: AST.
- Lowering pass: AST to high-level IR (e.g. Clang's `clang::Stmt` tree → MLIR or LLVM IR).
- Multiple optimisation passes on the IR: SSA construction, CSE, GVN, dead-code elimination, loop transformations, register allocation.
- Lowering to target machine instructions.

LLVM IR alone has ~60 instruction opcodes, three integer types beyond the platform native width, vector types, structured types, and a notion of blocks-with-arguments for SSA φ-functions. The IR is the central data structure of the compiler.

A Lisp compiler typically uses bytecode as its IR. SBCL goes further and has a CPS-based IR called IR1 plus a register-allocated lower IR called IR2. The IR is also where dynamic-language-specific optimisations happen: type inference, inlining of known primitives, dispatch elimination.

Our compiler has no IR. We go from AST to assembly directly, one statement at a time. This is the choice that distinguishes us most sharply from both C and Lisp implementations.

The reasons we make it work without an IR are documented in [middle-end-and-optimisation.md](middle-end-and-optimisation.md): one source language, no optimisation pressure, small enough programs that the cost of recompiling everything dominates anyway. A C compiler designer would be aghast at the omission; a Lisp compiler designer would point out that a small Lisp compiler can also skip the IR (early Lisp compilers did) and that the choice scales.

## Code generation

C compilers emit:

- Detailed prologues and epilogues per function: save callee-saved registers, allocate stack space, set up frame pointer (optionally).
- Calls following the platform calling convention, with argument promotion and aggregate handling.
- Function-pointer call sites (indirect calls through register).
- Branch-predicted control flow with hint instructions where the architecture supports them.
- Per-architecture instruction-scheduling decisions (which our compiler defers entirely to the assembler).

Lisp compilers emit:

- A single, large dispatch loop that walks the bytecode and executes each operation.
- Calls into a runtime that does most of the heavy lifting (allocation, GC, type dispatch).
- Substantial memory traffic compared to C, because every value is potentially heap-allocated.

INTERCAL compilers like ours emit:

- One labelled block per source statement, with abstain-flag and probability checks at the top.
- `bl` / `call` to a small set of runtime routines (`_rt_mingle`, `_rt_select`, `_rt_write_roman`, etc.).
- Per-platform syscall sequences for I/O and process control.

Our emitted code looks closer to a tail-end C compiler's output than to a Lisp compiler's. We do not have a dispatch loop; we have direct branches. We do not heap-allocate per-operation; we use fixed BSS slots.

## Memory model

C's memory model is a contract between the compiler and the programmer. Every variable lives at a specific address. The programmer can take addresses of variables, do arithmetic on them, and read or write through them. The compiler is responsible for making sure that "what looks like a write to a variable" actually reaches that variable's address (subject to some optimisation latitude, the as-if rule).

Lisp's memory model is opaque to the programmer. Every value is allocated on a heap (with the exception of fixnums and a few other immediate types in some implementations). A garbage collector reclaims memory periodically. The programmer cannot take addresses or do arithmetic on them.

INTERCAL's memory model is somewhere between the two:

- Scalars (`.N`, `:N`) live in fixed BSS slots. The programmer cannot take their address but the compiler exposes them through symbolic references.
- Arrays (`,N`, `;N`) are heap-allocated by the runtime via `mmap`. The compiler stores the pointer in a fixed slot. The programmer cannot manipulate the pointer directly but can grow and shrink the array via dimensioning.
- Stash stacks (per-variable LIFO) and the NEXT stack are runtime-managed structures the programmer can grow but not directly access.
- The reserved `,65535` array is a runtime-controlled buffer that the programmer agrees not to touch outside Label 666 syscalls.

There is no garbage collection. There is no `free`. Once an array is dimensioned, the runtime never reclaims its storage. This works because INTERCAL programs allocate arrays sparingly and the OS reclaims everything at process exit.

## Runtime services

C's runtime is the C standard library: malloc, free, printf, file I/O, math, string handling. Most of it is dynamically linked to every C program.

Lisp's runtime is much larger: garbage collector, type-tag dispatch, symbol table, condition system, eval (in many implementations), readline, debugger. A Lisp runtime is typically several megabytes.

Our runtime is a few hundred lines of platform-specific assembly per platform. It implements:

- Mingle, select, the unary operators.
- Roman numeral output.
- English digit-name input.
- Turing Text Model array I/O.
- mmap allocation.
- The NEXT stack helper.
- 16 error-exit routines.
- 8 Label 666 syscall handlers.

A C program could embed the same set of services in well under 10 KB. A Lisp program could not, even the smallest Lisp runtime needs a garbage collector. We sit at the C end of the runtime-size spectrum.

## Self-hosting

C compilers are routinely self-hosted: GCC and Clang both compile themselves. The mechanics are well understood and the bootstrap process is documented in their respective build instructions.

Lisp compilers are typically self-hosted too: SBCL, CMUCL, and many smaller Lisps compile themselves. The Lisp tradition explicitly emphasises this, a Lisp implementation that cannot bootstrap itself is rare.

INTERCAL has not, to public knowledge, ever been self-hosted. C-INTERCAL is written in C; CLC-INTERCAL is written in Perl. Our project's ambition to write `compiler.i` in INTERCAL (and reach a 3-generation fixpoint) is the first such attempt. Whether it succeeds is open; the current state is documented in [self-hosting.md](self-hosting.md).

## Performance

A modern C compiler's output is within ~2× of hand-written assembly for most workloads. The optimisation pipeline is what does this.

A modern Lisp compiler's output is typically 2–10× slower than equivalent C, depending on the program. The slowdown comes from runtime type dispatch, allocation pressure, and missed inlining opportunities.

Our compiler's output is many orders of magnitude slower than C, because we do no optimisation at all and call into the runtime for every operator. This is acceptable for our purposes (no production users) but would be a fatal flaw for a real implementation.

A future version of the compiler with a real IR and a few optimisation passes (constant folding, peephole, primitive inlining) could probably get within 5× of equivalent C. Whether the effort is worth it depends on whether anybody ever wants to run an INTERCAL program fast.

## Why this comparison matters

The language a compiler targets shapes every decision the compiler designer makes. C's complexity forces an elaborate front end and a substantial type checker. Lisp's flexibility forces an elaborate runtime and a lighter front end. INTERCAL's deliberate primitive-but-complete shape forces a tiny front end, a tiny back end, and a runtime that is small in code but large in conceptual responsibility.

A reader who expects a C-compiler-shaped implementation will be surprised by how little code we have. A reader who expects a Lisp-compiler-shaped implementation will be surprised by how primitive our runtime is. Both surprises are deliberate. The compiler is shaped exactly for the language it targets; departures from textbook shape come from the language, not from designer whim.

## Next reading

- [overview.md](overview.md): what we are.
- [middle-end-and-optimisation.md](middle-end-and-optimisation.md): what we deliberately do not have.
- [further-reading.md](further-reading.md): books that walk through C and Lisp compilers in their own right.
