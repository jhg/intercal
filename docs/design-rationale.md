# Design rationale — an FAQ

This chapter answers, in plain language, the questions that anybody seeing this compiler for the first time will reasonably ask. Each answer is short, self-contained, and points at the deeper chapters for readers who want more.

## Why write an INTERCAL compiler in 2026?

Because INTERCAL is the right size to be a complete teaching example. A full C compiler is too big to read through in a weekend; a pure regex engine is too small to illustrate more than a couple of phases. INTERCAL sits in the sweet spot: it has a lexer, a parser, a semantic-analysis phase, a code generator, a runtime, and a system library, and every one of those pieces fits in a few hundred lines.

See [overview.md](overview.md).

## Why no intermediate representation?

Adding an IR pays off when you have multiple source languages, multiple target backends, or want to run many optimisation passes. We have one source language (INTERCAL), two backends that share most of their structure (ARM64 and x86-64), and no performance pressure. An IR would be more work to build and maintain than the direct codegen it would replace.

See [middle-end-and-optimisation.md](middle-end-and-optimisation.md).

## Why zsh for the bootstrap?

Three reasons. First, universality: every system we target has zsh, so a bootstrap-from-scratch requires no extra toolchain. Second, transparency: the entire compiler is one file, and adding `set -x` dumps every phase. Third, appropriateness: INTERCAL is a 1970s-era language and zsh is a 1970s-era language-adjacent tool, which pairs well enough to feel deliberate.

See [self-hosting.md](self-hosting.md).

## Why not transpile to C like C-INTERCAL does?

Transpiling to C trades one complexity (emitting assembly) for another (matching INTERCAL semantics to C semantics). Some mismatches are awkward — signed overflow is undefined in C but must wrap in INTERCAL — and the dependency on a C compiler adds a hidden layer where bugs can hide. Direct-to-assembly removes that layer and lets us see exactly what runs.

See [code-generation.md](code-generation.md).

## Why not use a parser generator like Bison?

INTERCAL's grammar is LL(1) with ~15 productions. A Bison grammar file plus the generated parser is more code, not less, than a hand-written recursive-descent parser. The hand-written version is transparent: you can point at any production in the grammar and the corresponding function in `intercalc.sh`. A generated parser obscures this.

See [parser-theory.md](parser-theory.md).

## Why maintain two syslibs (pure INTERCAL and native assembly)?

The pure-INTERCAL syslib (9065 lines) is slow but is the authoritative specification of what each arithmetic routine does. The native assembly syslib (~300 lines per platform) is fast but translation-dependent. Running both implementations on the same inputs and diffing is a strong correctness test — it catches any bug that exists in only one of them.

See [syslib.md](syslib.md) and [testing-and-workflow.md](testing-and-workflow.md).

## Why Label 666 for syscalls?

Because INTERCAL-the-language has no syscall mechanism, and our self-hosted compiler cannot exist without one. Label 666 is the minimum extension that makes syscalls possible: one reserved label, a fixed-register convention for parameters, and a set of explicit syscall numbers. The name `666` is a deliberate nod to CLC-INTERCAL, which uses the same label for the same purpose (though with a different calling convention).

See [label-666-intro.md](label-666-intro.md) and [666.md](666.md).

## Why not just use CLC-INTERCAL's Label 666 as-is?

CLC-INTERCAL's Label 666 uses a parameter convention called "call by vague resemblance to the last assignment": the parameters live in whichever register was last assigned to in the program. This is deliberately obscure (consistent with INTERCAL's aesthetic) but hard to reason about. Our version uses fixed registers `.1` through `.4`. We lose binary compatibility with CLC-INTERCAL but gain a debuggable syscall mechanism.

See [666.md](666.md).

## Why self-host at all?

Self-hosting is the cleanest demonstration that a language is complete enough to express its own translation. Every compiler that reaches the fixpoint state (where the Nth-generation self-compile equals the (N+1)th) provides its own authoritative specification: the language is whatever the compiler understands. For INTERCAL specifically, self-hosting has never been done before; this project is trying.

See [self-hosting.md](self-hosting.md).

## Why a template-dispatch MVP before a real self-hosted compiler?

Because writing a full compiler in INTERCAL is estimated at 5000–15000 lines and months of work. We did not want to spend that effort before validating that the end-to-end self-hosted pipeline (Label 666, argv access, the reserved `,65535` buffer) could work at all. The template-dispatch MVP is ~40 lines of INTERCAL that proves the plumbing is viable; real compiler work follows in `stage3.i`.

See [self-hosting.md](self-hosting.md).

## Why `tests/run_tests.sh`, `tests/run_self_tests.sh`, and two more? Four suites?

Each suite tests a different layer of the stack. `run_tests.sh` validates the bootstrap compiler. `test_syslib_pure.sh` runs the pure-vs-native differential test. `run_self_tests.sh` validates the self-hosted MVP against the bootstrap. `run_stage3_tests.sh` validates the evolving real compiler. The layering is what lets us change a low-level component (say, a codegen function) and know exactly which suite would catch a regression.

See [testing-and-workflow.md](testing-and-workflow.md).

## Why TDD instead of writing code and then adding tests?

Because the cost of a miscompilation is high and often invisible. A bug that passes the existing tests but miscompiles one real-world INTERCAL construct might not surface until somebody writes a program using that construct. TDD — writing the test first — forces us to articulate what the new behaviour should be before writing code, which in turn catches wrong specifications at design time rather than at runtime.

See `AGENTS.md`, "TDD workflow".

## Why split the code generation between `intercalc.sh` and `codegen_x86_64.sh`?

ARM64 (macOS and Linux) shares almost all of its emitted assembly: small differences in syscall numbers, relocation syntax and entry-point names are patched with a `sed` post-processing step. x86-64 is a different architecture, so it needs a full codegen rewrite. Rather than one monolithic codegen with conditionals at every emission, we have one base codegen for ARM64 and a complete override for x86-64. Zsh's last-function-wins semantics makes the override trivial.

See [platforms.md](platforms.md).

## Why reserve `,65535` exclusively for Label 666?

Every Label 666 syscall that needs buffer data (open's filename, read's contents, argv's arguments) needs a well-known memory region. Reserving a specific array makes the interface portable between the compiler and the runtime without invention. The choice of 65535 (the largest 16-bit array index) keeps the reserved slot far from anything a normal program would use.

See [label-666-intro.md](label-666-intro.md).

## Why use `cc -x assembler -` rather than writing our own assembler?

Writing an assembler for Mach-O or ELF is a nontrivial project in its own right, and the system `cc` already does it correctly. The tradeoff is a dependency on `cc`, which is present on every system we target. We pay that dependency cost in exchange for not having to implement instruction encoding, relocation handling, and executable-format packaging.

See [executables-and-linking.md](executables-and-linking.md).

## Why three platforms and not just one?

Because a compiler that only works on one platform has not proved anything about its portability. The three-platform matrix (macOS ARM64, Linux ARM64, Linux x86-64) forces us to think about every platform-specific corner case at implementation time rather than when somebody later tries to port. The CI cost (three jobs instead of one) is worth the design pressure.

See [platforms.md](platforms.md).

## Why not support Windows?

Windows is on the roadmap but not yet implemented. The PE/COFF executable format, the Microsoft calling convention (different from System V AMD64), and the Win32 API rather than Unix syscalls all require substantial new code. We chose to stabilise the Unix targets first; Windows will follow.

## Why pre-generate test templates rather than actually compiling them?

Because the self-hosted MVP is not yet a real compiler. It is a template dispatcher. For the 25 test programs we care about, we have pre-generated the exact assembly the bootstrap compiler would produce, and the MVP's job is just to recognise each program and emit its matching template. When `stage3.i` becomes a real compiler, the templates become a cross-check (MVP output should match stage3 output), not the source of truth.

See [self-hosting.md](self-hosting.md).

## Why not merge the bootstrap and the self-hosted compilers?

The bootstrap compiler (`intercalc.sh`, zsh) and the self-hosted compiler (`stage3.i`, INTERCAL) are two different programs because they are written in two different languages. They are expected to produce the same outputs for the same inputs once `stage3.i` is complete. Until then, they are parallel, and the bootstrap remains the reference. After the fixpoint is reached, `intercalc.sh` becomes mostly historical — a primordial spark that is no longer used except when somebody bootstraps from scratch.

See [self-hosting.md](self-hosting.md).

## Why enforce the politeness rule?

Because the language specification requires it. The politeness rule — between 1/5 and 1/3 of statements must use `PLEASE` — is INTERCAL's signature compile-time check. A compiler that silently ignores it is not really compiling INTERCAL.

Practically, the rule is also our only opportunity to fire a compile-time error. Every other check in the INTERCAL error catalogue is a runtime condition.

See [semantic-analysis.md](semantic-analysis.md).

## Why no optimisations?

We have no production users for whom performance matters. Every optimisation pass is additional code surface that can introduce miscompilations. Until either compile time or runtime becomes a real bottleneck, adding optimisations is negative-value work. The "middle end" chapter explains where the low-hanging fruit is, if we ever decide to harvest it.

See [middle-end-and-optimisation.md](middle-end-and-optimisation.md).

## Why put so much content in `docs/` instead of in the code comments?

Because the audience for this project includes readers who want to understand how compilers work without necessarily modifying this one. Those readers should be able to read connected prose. Inline comments serve a different purpose — quick tips for somebody modifying the code — and cannot substitute for a narrative explanation of why the code is shaped the way it is.

See the root [README.md](README.md) of `docs/` for the three reading paths.

## Why keep `AGENTS.md` in the repo root instead of under `docs/`?

Because `AGENTS.md` is the authoritative contributor contract — not narrative documentation. It is symlinked to `CLAUDE.md` because AI tools look for `CLAUDE.md`. Moving it under `docs/` would break the convention and add indirection for both human and AI readers.

See [ai-collaboration.md](ai-collaboration.md).

## Why "chispa primigenea" and not "primordial spark" in the code?

Bilingual developers, primarily Spanish. The Spanish phrase is in the code and in some commit messages as a project-specific signature. The English translation appears in the docs wherever a reader without Spanish would need to understand the reference.

## Anything else?

If you have a question the docs do not answer, open an issue or a PR. Answers added to this FAQ are encouraged.

## Next reading

- [overview.md](overview.md) — the technical overview.
- [what-is-intercal.md](what-is-intercal.md) — the plain-English introduction to the language.
- [further-reading.md](further-reading.md) — external resources.
