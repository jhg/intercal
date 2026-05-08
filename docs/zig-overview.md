# Zig (zigc), in shape

Zig is a systems programming language with a self-hosted compiler. The source lives at <https://github.com/ziglang/zig>. What makes it interesting in this book is twofold. First, Zig's bootstrap journey is the closest production parallel to ours: it went from a C++ implementation (`stage1`) to a self-hosted Zig implementation (`stage2`) the same way we are going from `intercalc.sh` to `compiler.i` to `stage3.i`. Second, Zig's `comptime` mechanism collapses generics, macros, conditional compilation, and reflection into one language feature, and that decision shapes the entire compiler architecture in a way nothing else in this Part does.

The lesson the Zig compiler teaches that nothing else does: a compile-time evaluation primitive can be the centre of gravity of a compiler. In Rust, `const fn` is a side feature. In Zig, `comptime` is the analyser. The `Sema` phase of zigc is the largest module in the compiler and the place where types, generics, conditional compilation, and constant folding all happen at the same time.

For a reader of this book, Zig is the production-scale mirror of what `stage3.i` would look like if our compiler were larger and the language were richer.

## The pipeline

A Zig source file goes through this sequence:

    source                    program.zig
      → tokens                lib/std/zig/tokenizer.zig
      → AST                   lib/std/zig/Ast.zig
      → ZIR                   src/AstGen.zig
      → AIR                   src/Sema.zig
      → machine code          src/codegen/{llvm,x86_64,aarch64,...}.zig
      → object                via embedded linker or libllvm
      → executable            via embedded linker (lld-equivalent) or system ld

Six stages, two intermediate representations (ZIR and AIR), and a choice of backends including LLVM, several self-hosted backends per architecture, and a C backend that transpiles Zig to C.

The lexer and parser sit in `lib/std/zig/`. They are part of the standard library, deliberately, because they are reused by tools like `zig fmt` and `zls` (the Zig language server). The AST is conventional: tokens with offsets, a node array, structural nodes for declarations, expressions, and statements.

`AstGen` (`src/AstGen.zig`) is the first compiler-specific phase. It walks the AST and emits ZIR, an instruction-list intermediate representation. ZIR is untyped: an instruction `add %1 %2` does not say whether the operands are integers or floats. ZIR mixes runtime instructions and `comptime`-only instructions. The split between which is which only resolves later, in Sema.

`Sema` (`src/Sema.zig`) is the elephant: a tree-walking interpreter over ZIR that produces AIR (Analyzed IR). AIR is typed and contains only runtime instructions; everything `comptime` has been resolved into values. Sema does type checking, comptime evaluation, generic instantiation, monomorphisation, and conditional compilation simultaneously, in one pass. There is no separate type-check phase, no separate const-eval phase. They are inseparable in zigc by design.

After Sema, codegen lowers AIR to machine code. Multiple backends coexist in `src/codegen/`:

- `llvm.zig`: production backend via libllvm. Emits LLVM IR, links against LLVM.
- `c.zig`: C backend. Transpiles Zig to C. Useful for porting Zig to platforms before a native backend exists.
- `spirv.zig`: SPIR-V backend for GPU compute targets.

Plus per-architecture self-hosted backends in `src/arch/`:

- `x86_64/CodeGen.zig`: x86-64 native backend, no LLVM.
- `aarch64/CodeGen.zig`: AArch64 native backend.
- `riscv64/CodeGen.zig`: RISC-V 64 native backend.
- `wasm/CodeGen.zig`: WebAssembly native backend.
- `sparc64/CodeGen.zig`: SPARC64 native backend.

The list is not closed; new architectures are added as the project evolves.

The self-hosted backends exist for fast debug builds. They produce less-optimised code than LLVM but compile orders of magnitude faster, which matters for iteration. Production release builds typically use LLVM; debug builds increasingly use the self-hosted backends as they mature.

## Why ZIR and AIR are different

This is one of the design decisions worth pausing on. Most compilers have a single intermediate representation that gets gradually transformed. Zig has two distinct representations because they serve very different purposes.

ZIR is the output of pure parsing-plus-naming. It is constructed without knowing types. Its instructions can mix runtime and comptime computations because Sema has not yet decided which is which. ZIR for a function exists per-source-file and is cached: changing one file does not invalidate the ZIR of another.

AIR is the output of Sema for a particular function instantiation. It is typed. Generic functions produce AIR per-instantiation; an `ArrayList(u32)` and an `ArrayList(f64)` produce different AIR. Comptime values are baked in as constants. Conditional-compilation branches that were not taken are absent.

The two representations are different on purpose. ZIR captures the source's structure independent of types and uses; AIR captures one specific concrete instantiation ready for codegen. The transformation between them is the job of Sema, and the transformation is non-trivial precisely because it involves type inference, comptime execution, and generic instantiation in one pass.

For a reader coming from rustc, the analogy is HIR-vs-MIR, but with the twist that Sema is doing what rustc's type checker, miri, and monomorphiser do all at once.

## Sema, in detail

Sema is the central object of study. As of recent Zig (around 0.14), `src/Sema.zig` is a single Zig file of roughly 35,000 lines, growing over time.

What Sema does:

- Type checks all expressions and statements.
- Evaluates comptime expressions by interpreting ZIR directly.
- Resolves generic functions: every distinct instantiation produces new AIR.
- Performs conditional compilation: comptime-known `if` branches not taken are not lowered to AIR.
- Implements built-in functions (`@TypeOf`, `@typeInfo`, `@field`, etc.) as Sema-internal calls.
- Inlines functions marked `inline` or `@inlineCall`.
- Maintains the comptime allocation arena.

The implementation is a tree-walking interpreter. There is no SSA form at this stage; ZIR is a linear instruction list, and Sema processes it in order, with a stack-of-scopes and a stack-of-frames structure for handling control flow.

Performance characteristics: Sema is the bottleneck of zigc. A generic function that is instantiated many times (a typical container, used at many element types) runs Sema once per instantiation. Type-rich code can produce surprisingly long compile times. The Zig core team has invested heavily in incremental compilation precisely because Sema is the hot path.

The implementation language constraint matters too. Sema is itself written in Zig, including comptime Zig. The compiler uses comptime to implement the comptime feature: for instance, the `@typeInfo` function returns a tagged union that is itself defined in `lib/std/builtin.zig`, and Sema reads that file's structure at compile time of zigc.

A self-hosting compiler implementing its own most distinctive feature is a recurring shape in this Part. Rust's `core::intrinsics` are written in a Rust subset. OCaml's compiler implements modules using its own module system. Zig's compiler implements comptime by using comptime. The shape rewards careful design: the feature has to be expressive enough that the compiler itself benefits from it.

## Comptime: what it actually is

`comptime` is a marker that can be applied to:

- function parameters: `fn foo(comptime T: type, x: T) T { ... }`
- variable declarations: `comptime var i = 0;`
- block statements: `comptime { @compileLog("debug"); }`
- expressions: `const x = comptime fib(20);`

Plus the related modifier `inline` for forced compile-time control-flow expansion (e.g., `inline for`, `inline while`, `inline fn`).

What comptime can do: anything Zig can do, except observable side effects (no I/O, no syscalls, no FFI). Loops, recursion, allocation against the comptime arena, error handling, generics: all permitted. There is no syntactic subset like Rust's `const fn`. Whether a function can run at comptime is determined by what it does, not by a marker on its declaration.

What comptime allows in practice:

- **Generics as comptime functions**:

      fn List(comptime T: type) type {
          return struct {
              items: []T,
              len: usize,
          };
      }
      const IntList = List(i32);

  `List` is a function. It runs at comptime. It returns a value of type `type`. That value is then used as a type elsewhere. The compiler does not have a separate "generic instantiation" pass; instantiation is just calling `List` with a particular argument.

- **Reflection at compile time**:

      fn fieldNames(comptime T: type) []const []const u8 {
          const fields = @typeInfo(T).Struct.fields;
          var names: [fields.len][]const u8 = undefined;
          inline for (fields, 0..) |field, i| {
              names[i] = field.name;
          }
          return &names;
      }

  `@typeInfo(T)` returns a struct describing T's type structure. The function builds an array of field names at compile time. The result is a constant.

- **Conditional compilation as a normal `if`**:

      if (builtin.os.tag == .linux) {
          syscall_linux(...);
      } else {
          syscall_macos(...);
      }

  When `builtin.os.tag` is a known comptime value (which it always is in Zig), the not-taken branch is discarded. There is no `#if`, no `cfg!`, no separate language for conditional compilation.

- **Generic specialisation as a side effect of caching**: every distinct comptime argument produces a new instantiation. The compiler caches instantiations by argument value, so calling `List(i32)` twice produces one definition.

The flip side of this expressive power is that the boundary between "this works" and "this does not" is not always obvious. A comptime function that tries to use a runtime-only operation (an external function call, for instance) fails late, after Sema has already gone deep into evaluation. Zig's error messages have improved over time, but the dependency between comptime feasibility and the runtime/comptime classification of every operation it touches makes them harder to debug than Rust's pre-checked `const fn` boundary.

## Self-hosted backends and the LLVM exit ramp

Zig has had multiple backends since stage2 was promoted. The `--release` builds use LLVM by default; `--debug` builds increasingly use self-hosted backends.

Why have self-hosted backends at all? The straightforward answer is compile speed: LLVM is slow per function, and Zig values fast iteration. The deeper answer is that LLVM is a large, C++-flavoured dependency that complicates Zig's bootstrap and distribution. A self-hosted toolchain that does not need libllvm is a simpler thing to ship.

The current state varies per architecture. x86-64 self-hosted is the most mature; AArch64, RISC-V, and WebAssembly trail. The roadmap toward "no LLVM in any default path" is multi-year, but the direction is clear.

Code-quality tradeoff: self-hosted backends produce code that is functionally correct but not optimised the way LLVM optimises. There is no inlining heuristic, no vectorisation, no loop unrolling, no aggressive instruction scheduling. For debug builds, this is fine. For release builds, LLVM remains the production choice in 2026.

The 2025 milestone: the self-hosted x86_64 backend became the default in Debug mode on Linux and macOS. It passes around 1,987 behaviour tests (more complete in language coverage than the LLVM backend in some areas) and produces 5-50% faster wall-clock builds depending on the project. Windows still defaults to LLVM because the COFF linker work is incomplete. A new from-scratch aarch64 backend was merged in July 2025 (PR 24536) and will benefit from a recently added Legalize pass shared across backends. Release mode still uses LLVM on every architecture; production-ready self-hosted Release is the next milestone.

The architectural lesson: a project can pre-emptively build the alternative to its current dependency, and migrate gradually. This is rare. Most compilers commit to LLVM (Crystal, Rust, Swift, Julia) or commit to their own backend (Go, Haskell's NCG, OCaml's native, GCC) without gradual transition. Zig is one of the few that is mid-transition in production.

## `zig cc` and cross-compilation

A Zig oddity that changed how some C/C++ projects build: `zig cc` is a drop-in replacement for `gcc` or `clang`, backed by the LLVM bundled in Zig, with bundled musl libc, macOS SDK headers, and Windows SDK pieces. Setting `CC=zig cc` in a Makefile gives you cross-compilation for free, without installing a cross-toolchain.

This works because Zig ships with everything: the LLVM frontends for C and C++, headers for every supported platform, sysroot equivalents per target. `zig cc -target aarch64-linux-musl ...` produces a Linux ARM64 musl binary on macOS without any extra setup.

For projects that adopted `zig cc`, the trick has been transformative. Bun (the JavaScript runtime) builds via Zig precisely for this reason. Some C projects use `zig cc` only for cross-compilation and stick to gcc/clang for native builds.

For a reader of this book, the relevant lesson is: a compiler can ship the entire toolchain, including platform headers and sysroots, as a self-contained package. Our INTERCAL compiler does the analogous thing at small scale: the runtime and syslib ship with the compiler, and `cc` is the only external dependency. Zig pushes this further by also bundling the platform SDKs.

## The stage1 → stage2 → stage3 history

This is the part of Zig that mirrors our project most directly.

- **Stage1** (2015 to ~2022): the original Zig compiler, written in C++. It implemented enough Zig to compile the second compiler. Like our `intercalc.sh`.
- **Stage2** (2020 onwards, mainline since 2022): the self-hosted Zig compiler, written in Zig. Compiled by stage1 initially, then by itself. Equivalent to our `compiler.i` and (eventually) `stage3.i`.
- **Stage3** in Zig parlance was originally the conceptual third generation; in practice the project treats stage2 as the compiler and validates that it can self-compile. Equivalent to our 3-generation fixpoint.

The bootstrap mechanics today:

1. The repo contains `stage1/zig1.wasm`, a WebAssembly file containing a stripped-down stage2 compiler.
2. A small C program (generated from the wasm) interprets the wasm.
3. Running that interpreter against the current stage2 source produces a native stage2 binary.
4. The fresh stage2 then self-compiles to verify the fixpoint.

The zig1.wasm artifact is, in spirit, the same kind of "primordial spark" that our `intercalc.sh` provides for INTERCAL. A small bootstrap that contains just enough to start the self-hosting chain.

The deprecation of stage1 (the C++ compiler) was a milestone celebrated by the community. After it, the repo had no C++ in the main compiler path; everything was Zig. This is a real-world example of completing a self-hosting transition, and it is documented in Andrew Kelley's blog posts on ziglang.org from 2021-2022.

## Allocator-aware standard library

Zig's standard library does not have a global allocator. Every container, every dynamic data structure, takes an allocator as an explicit parameter. There are several allocator implementations in the standard library:

- `std.heap.page_allocator`: minimal, pages from the OS
- `std.heap.GeneralPurposeAllocator`: production-grade, with leak detection
- `std.heap.ArenaAllocator`: free-everything-at-once
- `std.heap.FixedBufferAllocator`: bump allocator on a fixed buffer
- `std.heap.c_allocator`: malloc/free wrapper
- `std.testing.allocator`: leak-detecting allocator for tests

Why this matters for the compiler: it is the most concrete embodiment of "explicit control" as a language design principle. Where Rust pushes ownership into the type system, where Go hides allocation behind GC, Zig keeps allocation explicit at every API boundary.

This affects the compiler's own implementation: Zig's compiler uses arena allocators heavily for transient data (parsing, Sema) and explicit allocators for persistent state. There is no implicit allocator anywhere. Reading any Zig data-structure module is reading explicit allocation pattern after explicit allocation pattern.

The pedagogical take: a language with no global allocator forces the API designer to think about lifetimes at every step. The result is code that is harder to write at first and easier to reason about later.

## Error union types

Zig's error handling is a sister to Rust's `Result<T, E>` but built into the syntax: `error{Foo, Bar}!T` is a value that is either an error from `{Foo, Bar}` or a value of type `T`. Errors are values, not exceptions; there is no stack unwinding.

The compiler implementation uses a discriminant byte (or tag, depending on the size) plus the value, with a small special-case path for the common pattern of "error union of pointer types" using the null-pointer trick to encode both states in one machine word.

The relevance for this book is that the compiler implementation has to translate every `try` into a check-and-early-return at a runtime boundary. Tracking the set of possible errors a function can produce ("error inference", a Zig feature) is a Sema-level dataflow analysis: which errors does each call site contribute to the overall set of errors a function can raise?

For a reader, error unions are a clean example of a sum type at the semantic level translated to a tagged union at the runtime level, with the language semantics chosen to make that translation efficient. They are easier to compile to fast code than exceptions; the compiler does not need an unwinder, does not need landing pads, does not need exception tables. The runtime cost of `try` is a single conditional branch.

## Repo layout

    src/
      Sema.zig                  The elephant: type checking + comptime + Sema
      AstGen.zig                AST → ZIR
      Air.zig                   AIR data structure
      Module.zig                Module-level state and the orchestrator
      codegen/
        llvm.zig                LLVM backend
        c.zig                   C backend
        spirv.zig               SPIR-V backend
      arch/
        x86_64/                 x86-64 self-hosted backend
        aarch64/                AArch64 self-hosted backend
        riscv64/                RISC-V 64 self-hosted backend
        wasm/                   WebAssembly self-hosted backend
      link/                     Linker (ELF/Mach-O/COFF/Wasm)
      Compilation.zig           Compilation driver
      main.zig                  CLI entry point
    lib/
      std/                      Zig standard library
      std/zig/                  Tokenizer, parser, AST, used by tools
      std/builtin.zig           Definitions Sema reads at comptime (e.g., @typeInfo result types)
    build.zig                   Zig's build script (Zig itself)
    stage1/zig1.wasm            Bootstrap WASM blob
    test/                       Test suite

The `lib/std/zig/` choice is worth noting: putting the parser in the standard library means tools like `zig fmt`, `zls`, and any third-party formatter can use the same parser. It is the "compiler-as-library" idea taken to a clean conclusion.

## Comparison with our INTERCAL compiler

| Aspect | INTERCAL compiler | zigc |
|--------|-------------------|------|
| Bootstrap | intercalc.sh (zsh) → compiler.i → stage3.i | C++ stage1 → Zig stage2 → fixpoint |
| Primary language | INTERCAL | Zig |
| Distinguishing feature | Politeness rule, COME FROM | comptime |
| IRs | None (parse tree only) | ZIR (untyped) + AIR (typed) |
| Backends | Direct codegen per architecture | LLVM + 4 self-hosted + C + SPIR-V |
| Self-hosting status | MVP self-hosted; stage3 evolving | Fully self-hosted since 2022 |
| Codebase size | ~2,000 zsh + ~3,000 assembly + INTERCAL syslib | ~500,000 lines Zig |

The shapes are the same. The scale differs by two orders of magnitude. The choice points are similar: own backends or borrow LLVM, self-hosting strategy via a small bootstrap blob, compiler-as-library for tooling.

## Reading order

A practical path for somebody who wants to get acquainted:

1. Read the [Zig language reference](https://ziglang.org/documentation/master/) up to the `comptime` section.
2. Browse `lib/std/zig/Ast.zig` to see the AST.
3. Open `src/AstGen.zig` and read a few simple ZIR-emission functions.
4. Open `src/Sema.zig` and search for `analyze_block`. Watch how the recursion descends and how comptime evaluation interleaves with type checking.
5. Read one self-hosted backend, `src/arch/x86_64/CodeGen.zig`. It is the most legible production backend in this Part.
6. Read Andrew Kelley's blog posts about deprecating stage1 if you want the bootstrap story.

## How to contribute

GitHub PRs to <https://github.com/ziglang/zig>. The community is young and active. Live discussion on Discord (linked from ziglang.org). The bug tracker has labels including `good first issue`.

Beginner-friendly categories:

- Standard library improvements: `lib/std/` is broad and many functions are straightforward.
- Self-hosted backend bugs: small, well-scoped, immediately testable.
- Documentation: the language reference is comprehensive but the compiler internals are mostly source-code-only.
- Sema bugs: harder, but the most direct path to learning the compiler's heart.

Build:

    git clone https://github.com/ziglang/zig
    cd zig
    cmake -B build -GNinja
    ninja -C build install

Builds need a stage1 binary (downloadable from ziglang.org/download) or a bootstrap from the `zig1.wasm` blob. Recent versions can also use a system Zig if available.

Tests:

    zig build test            # the full suite
    zig build test-stage2     # focus on stage2
    zig build test-cases      # behaviour tests

The full suite is large and can take an hour. PRs typically run a subset.

## Where to go next

- The Zig language reference at <https://ziglang.org/documentation/master/>.
- Andrew Kelley's blog (Zig founder) at <https://andrewkelley.me/> for design notes on the compiler.
- The Zig Software Foundation's developer notes on YouTube.
- [self-hosting.md](self-hosting.md) for our own bootstrap journey, structurally analogous.
- [from-intercal-to-real-compilers.md](from-intercal-to-real-compilers.md) for the bridge to the rest of Part VII.
