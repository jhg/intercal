# Contributing to a production compiler

The standard advice for contributing to a real compiler is "find a good first issue and fix it". The hard parts are picking a project to start with, getting its source to build, and learning how its review process works. This chapter walks each of those steps for the ten compilers covered in Part VII: LLVM, GCC, rustc, Go, GHC, OCaml, Cranelift, Zig, Swift, V8.

The book in your hands has prepared the conceptual ground. What follows is the practical residue.

## Pick a project that fits your interest

The ten compilers have different cultures and different on-ramps. None is universally easier than the others; they are different.

**LLVM** is modular by design. A new contributor often lands their first patch as a small optimisation pass, a target-specific instruction-selection improvement, or a documentation fix. The codebase is large but each pass is largely self-contained, and you can write an entire new pass in 200 lines without reading much of the rest.

**rustc** has the [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/) explicitly aimed at new contributors. The compiler is in Rust, so if Rust is your stronger language, this is the most welcoming entry point. Most first patches concern diagnostic improvements, lint extensions, or small bugs in HIR/MIR-level checks.

**GCC** has a longer history and a different set of conventions (mailing-list patch review rather than GitHub PRs). The codebase is the most heterogeneous and has the steepest reading curve, but it also has the most breadth: more languages, more targets, more legacy systems supported. First patches often concern target-specific bugs in less-trodden architectures.

**Go (gc)** has a small, self-contained compiler in Go. The contribution flow goes through Gerrit (go-review.googlesource.com), which is unusual but well-documented. First patches often concern SSA optimisation rules in `.rules` files, runtime small bugs, or standard-library improvements.

**GHC (Haskell)** has a strong academic-paper-followed-by-implementation tradition. Contributions tend to be documented theoretically (a paper, an RFC, an issue) before being implemented. First patches concern error-message improvements, simplifier refinements, or library additions.

**OCaml** has a small, conservative review culture. The code is high quality and the maintainers value backwards compatibility. First patches tend to be small bug fixes or standard-library additions.

**Cranelift** has a small, welcoming community. The codebase is small enough that a single contributor can absorb most of it. First patches often add ISLE rules, refine regalloc2, or improve the documentation.

**Zig** has a young, active, personality-driven community. Andrew Kelley's vision shapes the project. First patches commonly improve the standard library, fix self-hosted backend bugs, or add platform support.

**Swift** is Apple-driven but open. The build is large (hours, ~50 GB) and the contribution flow is more formal than smaller projects. First patches typically improve diagnostics, refine SIL passes, or extend the standard library.

**V8** is Google-driven via Gerrit (chromium-review). The build is heavy and depends on `depot_tools`. First patches usually fix bugs in less-trafficked TurboFan paths or improve diagnostic tooling.

If you have no preference, rough ranking by approachability: **Cranelift** and **rustc** are the friendliest first projects. **Go** is excellent if you already know Go. **LLVM** is the best for general compiler skills. **GHC** and **OCaml** for theoretical depth. **GCC** if you want to land patches on production systems software for decades. **Swift** and **V8** are the heaviest lifts but offer access to two of the most-deployed compilers in the world. **Zig** is the most exciting if you want to contribute to a project still finding its shape.

## Build the project locally

This is the step that turns a curious reader into an actual contributor. Each compiler has clear instructions; allow a couple of hours the first time.

### Building LLVM

    git clone https://github.com/llvm/llvm-project.git
    cd llvm-project
    cmake -S llvm -B build -G Ninja \
      -DLLVM_ENABLE_PROJECTS="clang" \
      -DCMAKE_BUILD_TYPE=Debug
    ninja -C build

A debug build of just LLVM and Clang takes 15–30 minutes on a modern laptop. Release builds are faster to produce but give worse debugging. Most LLVM contributors keep both around.

### Building rustc

    git clone https://github.com/rust-lang/rust.git
    cd rust
    cp config.example.toml config.toml
    # Edit config.toml: set profile = "compiler" for new contributors
    ./x.py build

The first build is the slowest, an hour or so, because it bootstraps through three stages of rustc compiling itself. After that, incremental builds of single crates take seconds. The `x.py` driver wraps everything: `x.py test`, `x.py check`, `x.py doc`. Read the [rustc-dev-guide chapter on building](https://rustc-dev-guide.rust-lang.org/building/how-to-build-and-run.html).

### Building GCC

    git clone git://gcc.gnu.org/git/gcc.git
    cd gcc
    mkdir build && cd build
    ../configure --enable-languages=c,c++ --disable-multilib
    make -j$(nproc)

GCC is autoconf+make, not CMake. The build takes about half an hour. You almost always want `--disable-multilib` (skips 32-bit support) and a narrow `--enable-languages` list to reduce the build time.

### Building Go

    git clone https://go.googlesource.com/go
    cd go/src
    ./make.bash

Building Go requires a previous Go to bootstrap (Go 1.4 source or 1.17.13 binary, depending on the release). The Go install instructions document this. The build is fast (minutes).

To work on the compiler:

    cd src/cmd/compile
    go build .

This produces a fresh `compile` binary you can use via `go build -toolexec=...`.

### Building GHC

    git clone https://gitlab.haskell.org/ghc/ghc
    cd ghc
    ./boot
    ./configure
    hadrian/build

GHC's build system is Hadrian (newer) or the legacy Make-based system. Bootstrapping requires an older GHC, which `ghcup` can install. The first build is significant (~30 minutes); subsequent incremental builds are much faster.

### Building OCaml

    git clone https://github.com/ocaml/ocaml
    cd ocaml
    ./configure
    make
    make tests

OCaml's build is fast (~5 minutes on modern hardware) and self-contained. The repository ships a bytecode `boot/ocamlc` for bootstrapping, so no prior OCaml is needed.

### Building Cranelift

    git clone https://github.com/bytecodealliance/wasmtime
    cd wasmtime
    cargo build -p cranelift-codegen

Cranelift is Rust-only and builds with `cargo` like any Rust project. The build is fast (seconds for incremental, ~1 minute from scratch for just Cranelift, longer for the whole wasmtime).

### Building Zig

    git clone https://github.com/ziglang/zig
    cd zig
    cmake -B build -GNinja
    ninja -C build install

Building Zig requires a stage1 binary (downloadable from ziglang.org/download) or bootstrapping through `zig1.wasm` (the WASM-encoded bootstrap). Recent versions can use a system Zig if available. The build is moderately heavy (~30 minutes).

### Building Swift

    git clone https://github.com/apple/swift
    cd swift
    ./utils/update-checkout --clone
    ./utils/build-script --release-debuginfo

Swift's build is the largest of the ten. You need swift, llvm-project, and several swift-corelibs-* repos. Allow several hours and ~50 GB of disk for the first build. Apple provides `update-checkout` and `build-script` to manage this.

### Building V8

    fetch v8
    cd v8
    gn gen out/x64.optdebug --args='is_debug=true is_component_build=true'
    ninja -C out/x64.optdebug

V8 uses `depot_tools` (Chromium's tool suite). Install depot_tools first, then `fetch v8` clones the source plus dependencies. The first build is slow (~1 hour) and downloads many gigabytes of dependencies.

## Find an issue to start with

### LLVM

LLVM's issue tracker is at <https://github.com/llvm/llvm-project/issues>. Filter by `good first issue`. Beginner-friendly categories: documentation patches, small optimiser bugs, missing diagnostics, target-specific instruction-selection rules.

### rustc

rust-lang/rust has explicit beginner labels: `E-easy`, `E-mentor` (with a designated mentor), `E-help-wanted`. The triage tool at <https://triage.rust-lang.org/> surfaces actionable issues by area.

### GCC

GCC tracks bugs in Bugzilla at <https://gcc.gnu.org/bugzilla/>. There is no "good first issue" tag; `Severity: enhancement` tends to surface small improvements. The mailing list <gcc@gcc.gnu.org> is the place to ask.

### Go

Go uses GitHub issues with labels `Help Wanted` and `NeedsInvestigation`. Particularly approachable: SSA optimisation rules in `.rules` files, runtime small bugs, standard library improvements, vet checks, error-message fixes.

### GHC

GHC uses GitLab at <https://gitlab.haskell.org/ghc/ghc/-/issues>. Labels include `newcomer-friendly`. Approachable areas: error messages, library additions to `base` (via the Core Libraries Committee), simplifier refinements, documentation in `docs/`.

### OCaml

The OCaml repo at <https://github.com/ocaml/ocaml> uses standard GitHub issues. Look for labels related to small improvements or `area:stdlib`. Approachable areas: standard library, less-touched parts of the compiler, documentation.

### Cranelift

Cranelift issues live in <https://github.com/bytecodealliance/wasmtime/issues>, with the `cranelift` label and `good first issue` filter. The community is small enough that the maintainers actively mentor; asking on Zulip first is welcomed.

### Zig

Zig uses GitHub issues. Look for `bug` labels, `enhancement`, or `good first issue`. The standard library has many opportunities; the self-hosted backends have ongoing work; Sema bugs are the most challenging but most rewarding.

### Swift

Swift uses GitHub issues. The `StarterBug` label identifies easy starting points. The Swift project has formal evolution (swift-evolution proposals) for language-level changes.

### V8

V8 tracks issues in the Chromium issue tracker at <https://bugs.chromium.org/p/v8/issues>. The `Hotlist-Help-Wanted` label or "first contribution" searches help. The Discord/Slack channels of V8 contributors can also surface mentorship.

## Learn the review process

The compilers have different review cultures.

**LLVM** reviews patches via GitHub pull requests since 2024. Reviewers are subscribed by area. Style: clang-format. Tests in `llvm/test/` (lit + FileCheck).

**rustc** reviews on GitHub. Every PR needs an `r=<reviewer>` comment from a designated reviewer; bors is the merge bot. Stable/beta/nightly channels mean some changes need explicit team approval to backport.

**GCC** reviews patches by mailing list. Send a `git format-patch` to <gcc-patches@gcc.gnu.org>, with a description and ChangeLog entry. A maintainer responds with feedback or "OK to commit". Cadence is slower than GitHub.

**Go** reviews on Gerrit (go-review.googlesource.com). Use the `git-codereview` plugin. Each change needs at least one approval (`+2`) from a maintainer.

**GHC** uses GitLab merge requests at <https://gitlab.haskell.org/ghc/ghc>. Code review is rigorous, often with extensive technical discussion. Tests in `testsuite/`.

**OCaml** uses GitHub PRs at <https://github.com/ocaml/ocaml>. Conservative review culture; expect detailed feedback and multiple revisions.

**Cranelift** uses GitHub PRs at <https://github.com/bytecodealliance/wasmtime>. Welcoming community, code review by Chris Fallin and others. Style: rustfmt + idiomatic Rust.

**Zig** uses GitHub PRs at <https://github.com/ziglang/zig>. Active community, often with quick feedback. Style: zig fmt.

**Swift** uses GitHub PRs at <https://github.com/apple/swift>. Apple maintainers are the primary reviewers; external contributors welcomed.

**V8** uses Gerrit (chromium-review.googlesource.com). Uploads via `git cl upload` (depot_tools). Every CL needs OWNERS approval.

## Write the change like the project would

Before submitting, confirm you have:

- A test that fails before your change and passes after. All projects require this in some form.
- A change that conforms to the project's coding style (clang-format for LLVM and Swift, rustfmt for rustc and Cranelift, gofmt for Go, zig fmt for Zig, GNU style for GCC, project-specific for GHC and OCaml).
- A commit message that explains the *why*. The diff shows the *what*.
- A clear scope. Each change does one thing. Resist the temptation to also fix the unrelated thing you noticed.
- For mailing-list projects (GCC), a ChangeLog entry. For everyone else, a clear PR/CL description.

These habits are the same ones our [AGENTS.md](../AGENTS.md) imposes for this project. The discipline transfers directly.

## Read code before you write it

The single highest-value habit when getting started is reading the existing source for the area you intend to change. For each project:

- **LLVM**: read several existing passes in the directory you intend to add to. Study how they handle their data, write tests, name their files.
- **rustc**: read the rustc-dev-guide chapter for the area, then read the corresponding `compiler/rustc_*/` crate. The crate-level READMEs are short and to the point.
- **GCC**: read the relevant `gcc/doc/` chapter, then the existing functions in the file you are about to modify. Pay attention to the style of comments and macro use; GCC has more idiosyncratic conventions.
- **Go**: read the README in `src/cmd/compile/` first. Then read existing SSA rules in `cmd/compile/internal/ssa/gen/generic.rules` to absorb the style. For runtime work, read existing functions in `runtime/`.
- **GHC**: read the GHC Commentary chapter for the area, then read the equivalent module's source. Pay attention to comment style and the way papers are referenced.
- **OCaml**: read existing functions in the file you will modify. The OCaml codebase is dense but uniform; one file gives you the conventions of the whole project.
- **Cranelift**: read existing ISLE rules for the architecture you target. The code is small enough that the entire backend can be read in a week.
- **Zig**: read recent commits to the file you will modify. Andrew Kelley's commits set the style.
- **Swift**: read the docs in `docs/` for the area. Then read recent commits and several similar passes/diagnostics.
- **V8**: read the V8 blog posts for context, then the source files surrounding your change. The diagnostic tools (`--trace-opt`, `--print-code`) help you see what current code does.

This step is not optional. Reading half a dozen similar changes makes the first contribution roughly free; skipping it usually costs a long review thread.

## Realistic expectations

A first patch typically takes:

- An afternoon to identify a candidate issue.
- A day to set up the build and reproduce the bug.
- A day to implement the fix.
- A few days of review back-and-forth.
- A handful of minor revisions to land.

A week is a normal first-contribution timeline. Two weeks is also normal. A month is fine. The contributors who struggle most are the ones who expected an hour.

For mailing-list projects (GCC), expect longer cycles. A small GCC patch might take two weeks; a non-trivial one, a month or more.

For Apple-driven projects (Swift) and Google-driven (V8), expect formal review processes that can be slower for first-time contributors than for known ones.

## Where to go next

- Each compiler's overview chapter for structural orientation: [llvm-overview.md](llvm-overview.md), [gcc-overview.md](gcc-overview.md), [rustc-overview.md](rustc-overview.md), [go-overview.md](go-overview.md), [ghc-overview.md](ghc-overview.md), [ocaml-overview.md](ocaml-overview.md), [cranelift-overview.md](cranelift-overview.md), [zig-overview.md](zig-overview.md), [swift-overview.md](swift-overview.md), [v8-overview.md](v8-overview.md).
- [from-intercal-to-real-compilers.md](from-intercal-to-real-compilers.md): the conceptual bridge from this book's content to production-compiler work.
- [further-reading.md](further-reading.md): per-compiler resources.
