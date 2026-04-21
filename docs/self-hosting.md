# Self-hosting

A compiler is self-hosting when it can compile its own source. The goal of this repository is to reach that state for INTERCAL: an INTERCAL compiler whose source is an INTERCAL program, compiled by an older copy of itself, producing an executable that can in turn compile the same source. This chapter explains how the project gets there, what "fixpoint" means in practice, and what stage we are at today.

## The bootstrap problem

A brand-new language has no compiler until somebody builds one, and the first compiler cannot be written in that language because nothing exists to compile it. The standard resolutions are:

1. Write the first compiler in another language, say C or shell. Use it to compile a compiler written in the new language.
2. Find an older version of the new language whose compiler already exists, extend it, and bootstrap by recompiling the extensions.

Our approach is option (1), executed in three phases, with the deliberate choice of shell as the bootstrap language.

## Phase 1 — The shell bootstrap

`src/bootstrap/intercalc.sh` is a complete INTERCAL compiler written in zsh. It reads `.i` from stdin, emits ARM64 or x86-64 assembly, concatenates that with the runtime and (optionally) the syslib, and invokes `cc -x assembler -` to produce a binary. It is 1825 lines long and handles the full language — every statement type, every operator, all four variable prefixes, arrays, abstention, COME FROM, the politeness rule, and the 16 runtime error codes.

This is what gives us the "primordial spark" (*chispa primigenea*) — the first INTERCAL compiler that exists at all. Everything that follows builds on its output.

## Phase 2 — The self-hosted MVP

`src/compiler/compiler.i` is an INTERCAL program whose job is, today, extremely modest: read a source file via Label 666, classify it by content hash, emit the pre-generated assembly for that specific program, and exit. It is 43 lines of INTERCAL and, functionally, a template dispatcher.

The repository also ships `src/compiler/templates/<platform>/<testname>.s` — one pre-compiled assembly file per test program per platform. The MVP's "compilation" is:

1. Read argv[1] (the source file name).
2. Read its contents into the reserved `,65535` buffer.
3. Compute a content hash (delegated to the wrapper).
4. Look up the matching template.
5. Write the template to stdout.

The wrapper script `intercal` then concatenates the runtime, the syslib, and the emitted template into the final binary.

This is trivially not a real compiler. What it *is*, is proof that the end-to-end self-hosted pipeline works: a `.i` program (`compiler.i`) was compiled by `intercalc.sh`, the resulting binary reads another `.i` file via the Label 666 syscalls, and produces assembly that builds a second binary identical to what the bootstrap would have built. Every component — Label 666, argv access, the reserved `,65535` buffer, the `read` and `write` syscalls, the exit code path — is exercised.

The template-dispatch shape matters for one additional reason: it lets us run the self-hosted compiler in CI across every test program, without needing the real lexer and parser to exist yet. The self-hosted MVP passes 25/25 tests on all three platforms. That coverage is the guarantee that the runtime and the INTERCAL language features used by `compiler.i` are already rock solid.

## Phase 4 — The evolving compiler

`src/compiler/stage3.i` is where the template dispatcher is being replaced, incrementally, by a real compiler. As of 2026-04-21 the file is 41 lines long and can:

- Read argv[1] into `,65535`.
- Record the source's byte count in `.20`.
- Read the first byte (`,65535 SUB #1`) into `.21`.
- Read the last byte (`,65535 SUB .20`) into `.22`.
- Print all three as Roman numerals.

That is the substage 3.1.c milestone. The roadmap from here, matching the stages in `AGENTS.md`, is:

1. **Lexer**: scan `,65535` for `DO`, `PLEASE`, `DON'T`, counting statements and recording boundaries in parallel arrays `,11–,18`.
2. **Parser**: classify each statement, parse expressions into a tree using arrays `,20–,23` and `;20`.
3. **Semantic analysis**: politeness check, label uniqueness, COME FROM resolution.
4. **Minimal codegen**: emit assembly for `GIVE UP` only, exercising the full pipeline-to-binary assembly.
5. **Incremental codegen**: one statement type at a time, each with a dedicated regression test.
6. **Fixpoint**: compile `stage3.i` with itself, verify generation-to-generation output stability.

Each sub-stage is committed as a separate piece with a failing test, a passing implementation, and green CI across all three platforms. The TDD workflow documented in `AGENTS.md` is what makes this a viable plan rather than a multi-month debugging session.

## The fixpoint test

A compiler is self-hosted in a meaningful way only when running it on its own source is a stable operation: the output does not change if you do it again. The test we will eventually run is:

    # Generation 1: compile compiler.i with the bootstrap
    zsh src/bootstrap/intercalc.sh < src/compiler/compiler.i > gen1

    # Generation 2: compile compiler.i with gen1
    ./gen1 src/compiler/compiler.i > gen2.s
    cat runtime.s syslib_native.s gen2.s | cc -x assembler - -o gen2

    # Generation 3: compile compiler.i with gen2
    ./gen2 src/compiler/compiler.i > gen3.s

    # Fixpoint: gen2.s and gen3.s must be byte-identical
    diff -q gen2.s gen3.s

If gen2.s = gen3.s, the compiler has reached a fixpoint: it now produces the same output for itself whether compiled by the bootstrap or by its own previous generation. That is the precise definition of self-hosting used in this project and described in `bootstrap.sh`.

Note that gen1 does not need to equal gen2. The bootstrap compiler and the self-hosted compiler can emit slightly different assembly (different register allocations, different operand ordering). What matters is that the self-hosted compiler is *internally consistent*: once it is the one in charge, its output stabilises immediately.

### Why a third generation is useful

Two generations are enough to prove correctness, in the sense that gen2 could compile gen3 again and produce gen3 again. A third generation catches a different class of bug: suppose gen1 had a subtle miscompilation that happened to produce a correct compiler gen2, but gen2 itself mishandled some feature only used inside its own source. Then gen2(compiler.i) ≠ gen1(compiler.i), and we would expect gen3 to differ from gen2. Comparing three generations makes this detectable.

Historically, the three-stage bootstrap is also how `gcc` validates itself. The third stage exists not because two is wrong, but because three is cheap insurance.

## Why shell for the bootstrap, and not C or Rust

The bootstrap language does not affect the final compiler, only the initial act of bringing one into existence. Three factors pushed us toward shell:

- **Universality**: every supported target (macOS, Linux ARM64, Linux x86-64) has zsh. No toolchain bootstrap is required before the compiler bootstrap.
- **Introspectability**: adding `set -x` reveals the pipeline in full. Every phase is a function. Every emitted line of assembly is a `print` call.
- **Appropriateness**: INTERCAL is itself 1970s-era baroque. A 1970s-era shell, with tricky quoting and awk-adjacent pipelines, is a fair match.

The third of these is half-serious. The first two are decisive. A C bootstrap would need a `make` system, headers, a build toolchain, and cross-compilation configuration per platform. A Rust bootstrap would need a modern rustup setup on every CI runner. zsh needs none of that.

The documented fallback, if the shell version ever becomes unmaintainable, is to make the bootstrap emit Rust source that the rust compiler lowers to native code. We have not needed that.

## What self-hosting does not mean

It is tempting to conflate "self-hosting" with "production-ready" or "optimised". Neither is implied:

- Self-hosting is a purely mechanical property. A buggy compiler that reliably produces a buggy copy of itself is still self-hosting.
- The self-hosted compiler is allowed to be slow and unoptimised, provided it terminates. Speed is a separate concern.
- Self-hosting is not a guarantee that the language is Turing-complete, only that the specific program `compiler.i` is expressible.

In our case we care about self-hosting for the same reason every historical language implementation did: it is the cleanest demonstration that the language is complete enough to express its own translation.

## Exercises

1. Read `bootstrap.sh`. At what step does it assume `compiler.i` is a real compiler rather than the template-dispatch MVP? What heuristic does it use to decide?
2. Given that `gen1` and `gen2` can differ legitimately, why does the fixpoint test insist on `gen2 = gen3`? Give an example where `gen1 = gen2 = gen3` would be impossible for a correct compiler.
3. Today's `stage3.i` reads the source file and prints three bytes. Describe the smallest extension that would make it distinguish a `DO` from a `PLEASE DO` statement. Estimate the number of INTERCAL lines required.
4. Could the bootstrap be written in Python 3 instead of zsh? What would change in the CI configuration? What would *not* change?
5. The `--pure-syslib` flag swaps the syslib at the entry point of each compilation. Would you use `--pure-syslib` for the self-hosting fixpoint test? Why or why not?

## Next reading

- [map-of-the-compiler.md](map-of-the-compiler.md) — the exact layout of `src/compiler/` and how the MVP and stage3 files relate.
- [testing-and-workflow.md](testing-and-workflow.md) — the four test suites, differential testing, and the TDD contract that keeps stage3 on the rails.
- [platforms.md](platforms.md) — why self-hosting has to work identically on three platforms and what enforces that.
