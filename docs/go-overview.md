# Go (gc), in shape

The Go compiler, conventionally called `gc` (short for "Go compiler", unrelated to garbage collection), is the reference implementation of Go. Source lives at <https://github.com/golang/go> in `src/cmd/compile`. Unlike Clang or rustc, `gc` does not lean on LLVM, GCC, or any other backend. Frontend, middle end, backend, linker, runtime: all of it is Go, all of it is in the same repository, all of it builds itself.

That self-contained quality is the first thing to take in. Around 600,000 lines of Go cover the compiler proper (`cmd/compile`), with another 50,000 for the linker (`cmd/link`). Roughly half the compiler is generated from declarative SSA rewrite rules; the hand-written portion is about half that. There is no external dependency at compile time and no libc dependency at run time. The compiler decides stack vs heap allocation through escape analysis. The runtime ships its own scheduler for goroutines and its own concurrent garbage collector. The linker emits binaries for any of fifteen-odd targets without needing a system toolchain installed.

For a reader of this book, Go is the most direct counterpart to our INTERCAL compiler at production scale: zsh and assembly here, Go and Go assembly there, the same self-contained spirit.

## Pipeline, end to end

Go source goes through this sequence:

    source                                        program.go
      → tokens                                    cmd/compile/internal/syntax (lexer)
      → AST (syntax)                              cmd/compile/internal/syntax (parser)
      → AST (ir)                                  cmd/compile/internal/noder
      → typed AST                                 cmd/compile/internal/types2
      → AST after walk                            cmd/compile/internal/walk
      → SSA                                       cmd/compile/internal/ssa
      → machine code                              cmd/compile/internal/ssa (lowering)
      → object file                               cmd/compile/internal/obj
      → executable                                cmd/link

Eight stages, two ASTs, one SSA IR, one object format, and one linker. Each stage is a Go package that operates on the data structures of the next.

The lexer and parser are hand-written and live in `cmd/compile/internal/syntax`. They produce a syntactic AST that captures the program shape. The `noder` then translates that AST into the older `ir` package's representation, which is what the rest of the compiler historically expected.

Type checking happens in `cmd/compile/internal/types2`, a recent (Go 1.18+) reusable type checker that doubles as the type checker for `go/types` and tools like `gopls`. Generics support landed alongside `types2`. The output is a fully typed `ir` AST.

`walk` is the lowering pass. It rewrites high-level Go constructs into smaller primitives the SSA backend can handle. Range loops become explicit `for` loops. Channel sends and receives become calls into the runtime. Map operations become hash-table calls. `defer` becomes setup plus runtime registration. Slice literals become allocations plus stores. Most of the magical-looking Go syntax disappears here.

The output of `walk` is then converted to SSA function-by-function. The SSA backend optimises and lowers to machine code for the target. Codegen emits a Go-specific object format, not ELF/Mach-O directly, which is then consumed by `cmd/link` together with all other compiled packages and runtime code to produce the final executable.

## SSA with declarative rewrite rules

The SSA backend was added in Go 1.7 (2016) by Keith Randall and replaced the older 6g/8g code generators. It is the most distinctive part of the compiler.

The IR is conventional SSA: each value has a single definition, basic blocks form a control-flow graph, function arguments are block parameters of the entry block. What is unconventional is how optimisations are written.

Each architecture has a `gen/<arch>Ops.go` file that lists every SSA opcode the architecture supports. Each architecture also has a `gen/<arch>.rules` file that rewrites generic SSA into architecture-specific SSA, plus optimisation rules that fire at the right point in the pipeline.

A rule looks like this:

    (Add64 (Const64 [c]) (Const64 [d])) => (Const64 [c+d])
    (Add64 x (Const64 [0])) => x
    (Add64 (Const64 [c]) x) && c < 0 => (Sub64 x (Const64 [-c]))

The left side is a pattern over SSA nodes. The right side is the rewrite. Optional Go-language guards (`&& condition`) gate the rule. The whole `.rules` file is compiled to Go by `cmd/compile/internal/ssa/gen/rulegen.go` during the build, producing a function the SSA pipeline calls in each rewrite phase.

This is rare in production compilers. LLVM has TableGen for instruction selection but pass-level optimisations are conventional C++. Cranelift has ISLE for lowering but optimisations are also Rust. Go has `.rules` for both, in the same syntax. Reading `generic.rules` (~3500 lines, architecture-independent simplifications) is one of the most pleasant ways to learn what a SSA-form optimiser actually does.

The phases of the SSA pipeline live in `cmd/compile/internal/ssa/compile.go`. A typical Go function passes through about fifty named phases:

- `early phielim`, `early copyelim`: clean up the SSA construction
- `opt`: apply `generic.rules` rewrites until fixpoint
- `dse` (dead store elimination), `cse` (common subexpression elimination)
- `prove`: range analysis based on assertions and bounds checks
- `nilcheckelim`: remove redundant nil checks
- `late opt`, `loopRotate`, `late copyelim`
- `lower`: apply `<arch>.rules` to translate generic SSA to architecture-specific SSA
- `lateLower`: more architecture-specific cleanup
- `regalloc`: linear-scan-style register allocation on SSA
- `loop rotate`, `stackframe`, `trim`
- `genssa`: emit machine instructions

You can dump any phase with `go build -gcflags='-d=ssa/<phase>=<level>' program.go`. Higher levels print more detail. Reading SSA dumps for a small program (start with `go build -gcflags='-d=ssa/opt=2' program.go`) is the fastest way to learn the pipeline.

## Escape analysis

Go is a garbage-collected language, but the compiler tries to allocate on the stack whenever it safely can. The decision lives in `cmd/compile/internal/escape`.

The algorithm is a dataflow analysis over function summaries. Each variable is treated as a node in a graph. Edges represent "can the value of A flow into B". A variable escapes if a path exists from it to:

- the function's return value
- a global variable
- a heap-allocated structure
- the receiver of a method that may store it

Variables that do not escape are allocated on the stack. Variables that escape are allocated on the heap and become GC roots.

The lessons embedded here are subtle. Taking the address of a local variable does not by itself force heap allocation; only escaping the address does. Returning a pointer to a local typically forces heap allocation, but inlining can sometimes prove escape stays local and the allocation moves back to the stack of the caller. Closures capture variables; whether they escape depends on whether the closure itself escapes.

The contrast with Rust is illuminating. Rust solves the same problem at type level via the borrow checker: lifetimes are part of the type, escape is a compile error, no GC needed. Go solves it at IR level: escape is a runtime concept (heap-vs-stack), and what cannot be proven non-escaping defaults to the heap. Both are correct, both work, both teach the same underlying problem from opposite angles.

Reading both, side by side, gives a contributor a real intuition for how language design pushes complexity around: Rust pushes it to the type system, Go pushes it to the GC plus escape analyser. INTERCAL would push it nowhere because INTERCAL has no closures and no pointers, but the conceptual lesson transfers.

## Inlining

The inliner lives in `cmd/compile/internal/inline`. It is budget-based: each function carries a "complexity score" computed from its AST, and the inliner inlines callees while their score fits the caller's remaining budget.

Inlining matters in Go because so much of the standard library and so much of generic code is short. Without inlining, generic containers, the iteration protocol, and most runtime helpers would carry call overhead that competing languages elide.

The inliner has accumulated a few sophisticated tricks:

- mid-stack inlining (Go 1.12+): inline a function even if it itself calls something not inlined
- profile-guided inlining (Go 1.20+): use PGO data to bias the inliner toward hot call sites
- unified inliner (Go 1.20+): replaces the old "inline before walk" + "mid-stack inline after walk" split

A reader who wants to understand Go performance reads the inliner. A reader who wants to understand Rust performance reads `rustc_mir_transform/inline`. The algorithms are similar but the decisions are not, because Rust's monomorphisation already specialises generics aggressively before inlining can be considered.

## Runtime cooperation

The compiler does not stand alone; it cooperates with the runtime in several places. This cooperation is invisible from outside but central to the design.

Write barriers: the GC needs to know when a pointer in the heap is overwritten so it can update the marker state. The compiler inserts barrier calls at every pointer write that could be tracked. Walk handles part of this; ssa lowers it.

Stack growth: goroutines start with tiny stacks (2KB) that grow as needed by copying. The compiler emits a stack-check prologue at every function entry. If the stack would overflow, the prologue calls into `runtime.morestack`, which allocates a larger stack, copies the frame, and resumes.

Preemption: `sysmon` and the GC need to interrupt running goroutines at safe points. The compiler emits "safe point" annotations in machine code that runtime knows how to find for stack scanning and async preemption (Go 1.14+).

Schedule yield: certain operations (channel send/receive on a full/empty channel, `select`, network I/O) yield to the scheduler. The compiler turns these into runtime calls that may park the goroutine.

`defer` and `recover`: defer statements push a deferred call onto a per-goroutine stack at the point of declaration; the function epilogue (or a panic walk) pops and executes them. The compiler chooses between three implementations depending on shape: heap-allocated, stack-allocated, and open-coded (Go 1.14+, the cheapest, used when defers are statically determinable).

These are the places to look when learning how a compiler-runtime contract is structured. The compiler emits machine code that knows about runtime invariants; the runtime relies on the compiler to maintain them. Bugs in either side manifest as crashes that look like the other side's fault.

## Linker and object format

Go has its own linker (`cmd/link`) and its own object format. The format is described in `cmd/internal/goobj`. It is not ELF, not Mach-O, not COFF: it is a Go-specific intermediate that the linker reads and turns into the target executable format.

The linker handles:

- symbol resolution across packages
- dead-code elimination at link time (functions not reachable are dropped)
- DWARF generation for debugging
- buildinfo embedding (the `runtime.buildVersion` string and friends)
- type metadata for reflection (the `_type` and `interfacetype` structures)
- target-specific ELF/Mach-O/PE/Wasm emission

Reading `cmd/link` is one way to learn linkers without diving into LLD or GNU ld. It is much smaller (~80,000 lines) and the abstractions are tighter because there is one frontend and one runtime. It is, in effect, a self-contained linker textbook.

## Cross-compilation

`GOOS` and `GOARCH` environment variables select the target. Setting `GOOS=linux GOARCH=arm64 go build` produces a Linux ARM64 binary on macOS without any cross-toolchain installation. There is no `--target` flag, no Clang `-target=arm64-linux-gnu` style; it is in the build invocation itself.

This works because the compiler has every supported backend compiled in, the linker can emit every supported format, and the runtime is included as Go source for every target. Targets supported as of Go 1.22+ include: linux/{amd64,arm64,arm,386,riscv64,mips64,ppc64,s390x,loong64}, darwin/{amd64,arm64}, windows/{amd64,arm64,386}, freebsd, openbsd, netbsd, dragonfly, plan9, solaris, illumos, aix, ios, android, js/wasm, wasip1.

For somebody coming from a C/C++ world where cross-compiling is a recurring pain (sysroot, libc choice, header copies, libstdc++), Go's approach is striking. The price is that adding a new target means writing a Go-side backend, not piggy-backing on LLVM. The benefit is that everyone gets cross-compilation as a natural property of using the language.

## Bootstrap

`gc` is self-hosted. To build it from source you need an older Go to bootstrap. The chain:

- Pre-1.5: the compiler was written in C as `6c`/`8c`/`5c` and translated to `6g`/`8g`/`5g` for Go targets.
- Go 1.5: a semi-automated translation rewrote the compiler in Go. From this point on, Go itself was needed to build Go.
- Since Go 1.22 the bootstrap rule is "Go 1.N requires Go 1.M, where M is N-2 rounded down to even", so Go 1.22-1.23 require Go 1.20.x and Go 1.24+ require Go 1.22.x. When bootstrapping from older sources, you chain through previous releases (Go 1.4 from C, then a 1.17.13 binary, then forward).

`gccgo` is a separate frontend in GCC that uses GCC's optimiser instead of `gc`'s SSA. It is slower to compile, occasionally produces faster code, and is the way to use Go on architectures `gc` does not support. The Go ecosystem effectively maintains two production compilers, used in different niches.

## Repo layout

    src/cmd/compile/internal/
      syntax/       Lexer + parser, syntactic AST
      noder/        Syntactic AST → ir AST
      types2/       Type checker
      ir/           "Old" AST (typed, used by walk and through SSA construction)
      walk/         Lowering of high-level constructs
      escape/       Escape analysis
      inline/       Inliner
      ssa/          SSA backend
        gen/        Op definitions and rewrite rules per architecture
      ssagen/       AST → SSA conversion
      <arch>/       Per-architecture glue (amd64, arm64, riscv64, ...)
      base/         Compiler-wide configuration and command-line flags
      typecheck/    Old typechecker (legacy, gradually superseded by types2)

    src/cmd/link/                 Linker
    src/cmd/asm/                  Assembler (Go's assembly dialect, not GNU)
    src/cmd/internal/goobj/       Object format
    src/cmd/internal/obj/<arch>/  Per-architecture instruction encoding
    src/runtime/                  Runtime: scheduler, GC, channels, defer, panic
    src/runtime/mgc*.go           Garbage collector implementation
    src/runtime/proc.go           Scheduler
    src/runtime/netpoll*.go       Network poller (epoll/kqueue/IOCP)
    src/runtime/sys_*_*.s         Per-OS, per-arch syscall stubs

The Go assembler dialect deserves a footnote. Go's assembler is not GNU as. It uses a Plan 9-derived syntax where each architecture is described in terms of pseudo-registers and pseudo-instructions that the assembler lowers to native ones. Reading `runtime/asm_amd64.s` for the first time is a small culture shock; the conventions are documented at <https://go.dev/doc/asm>.

## Comparison with other compilers

| Aspect | gc | LLVM (Clang) | rustc | INTERCAL compiler |
|--------|----|--------------|-------|-------------------|
| IR levels | 2 (ir AST + SSA) | 1 (LLVM IR) | 4 (HIR/THIR/MIR/LLVM IR) | 0 (parse tree only) |
| Backend | Self (gen+rules) | LLVM | LLVM (default) | Self (templates) |
| Linker | Self (cmd/link) | LLD or system ld | LLD or system ld | system cc as driver |
| Optimisations | ~50 SSA passes, declarative rules | ~200 passes, C++ classes | MIR transforms + LLVM passes | constant fold, peephole, dead-flag |
| Self-hosted | Yes | No (C++) | Yes (Rust) | Yes (INTERCAL via stage3) |
| Cross-compile | Built-in via GOOS/GOARCH | --target with sysroot | --target with sysroot | macOS arm64, Linux arm64+x86-64 |
| Codebase | ~50K Go (compile) + ~80K Go (link) | ~10M C++ | ~3M Rust | ~2K zsh + assembly |
| Compile speed | Very fast (package parallel) | Slow (single-threaded per TU) | Slow (heavy IR) | Instant |

The shape Go shares with our INTERCAL compiler is "do it yourself, top to bottom". Go does it at production scale; we do it at toy scale. The decision points are the same: own backend or borrow LLVM, own linker or invoke `cc`, own runtime or rely on libc.

## Reading order

For a contributor who wants to land a first patch on Go in roughly a month:

1. Read the Go programming language tutorial at <https://go.dev/tour/> if you do not already know Go.
2. Read [the rustc-overview equivalent for Go](https://go.dev/src/cmd/compile/README), the README in `src/cmd/compile`. Short and orienting.
3. Browse `src/cmd/compile/internal/syntax/parser.go`. A real, hand-written, recursive-descent parser at production scale. ~3000 lines, excellent reading.
4. Open `src/cmd/compile/internal/ssa/gen/generic.rules`. Read the first 200 lines until the patterns become natural. This is where most algebraic simplification lives.
5. Pick a phase from `compile.go` and read its source. `dse.go` (dead store elimination) is short and self-contained.
6. For runtime, read `runtime/proc.go` for the scheduler, `runtime/mgcmark.go` for the GC marker, `runtime/netpoll_epoll.go` for the network poller.

## How to contribute

Go uses Gerrit, not GitHub PRs. The flow:

    git clone https://go.googlesource.com/go
    cd go
    git config remote.origin.review https://go-review.googlesource.com
    git codereview change   # creates a branch + commit
    # ...edit, test...
    git codereview mail     # sends to Gerrit for review

The `git-codereview` plugin is a wrapper documented at <https://go.dev/doc/contribute>. Reviews happen on go-review.googlesource.com. Each change needs at least one approval (`+2`) from a maintainer.

Beginner-friendly issues are tagged `Help Wanted` and `NeedsInvestigation` on <https://github.com/golang/go/issues>. Particularly approachable categories: SSA optimisation rules in `.rules` files (declarative, easy to test), runtime small bugs, standard-library improvements, vet checks, error-message fixes.

Tests use Go's own testing framework. The `test/` directory at the repo root holds end-to-end tests that exercise the compiler on small Go programs. Each new optimisation rule should come with a test in `test/` that exercises the pattern.

## Where to go next

- The Go internals series at <https://internals-for-interns.com/posts/understanding-go-runtime/> walks the runtime piece by piece. Pairs naturally with our [runtime.md](runtime.md), where the same questions ("what does the runtime have to do that the language can't?") come up at INTERCAL scale.
- Sazak's Go internals series at <https://sazak.io/series/go-internals> covers the SSA backend and walk pass in detail.
- The community-maintained <https://github.com/emluque/golang-internals-resources> indexes most extant Go internals material.
- Russ Cox's blog at <https://research.swtch.com/> contains many of the original design notes for the Go compiler and runtime.
- [llvm-overview.md](llvm-overview.md) and [cranelift-overview.md](cranelift-overview.md) for backends that take other approaches.
- [contributing-to-production-compilers.md](contributing-to-production-compilers.md) for a side-by-side comparison of contribution flows across the compilers in this Part.
