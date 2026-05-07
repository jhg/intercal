# Contributing to a production compiler

The standard advice for contributing to a real compiler is "find a good first issue and fix it". The hard parts are picking a project to start with, getting its source to build, and learning how its review process works. This chapter walks each of those steps for the three compilers most readers will reach for: LLVM, rustc, GCC.

The book in your hands has prepared the conceptual ground. What follows is the practical residue.

## Pick a project that fits your interest

LLVM, rustc, and GCC have different cultures and different on-ramps. None is universally easier than the others; they are different.

**LLVM** is modular by design. A new contributor often lands their first patch as a small optimisation pass, a target-specific instruction-selection improvement, or a documentation fix. The codebase is large but each pass is largely self-contained, and you can write an entire new pass in 200 lines without reading much of the rest.

**rustc** has the [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/) explicitly aimed at new contributors. The compiler is in Rust, so if Rust is your stronger language, this is the most welcoming entry point. Most first patches concern diagnostic improvements, lint extensions, or small bugs in HIR/MIR-level checks.

**GCC** has a longer history and a different set of conventions (mailing-list patch review rather than GitHub PRs). The codebase is the most heterogeneous and has the steepest reading curve, but it also has the most breadth: more languages, more targets, more legacy systems supported. First patches often concern target-specific bugs in less-trodden architectures.

If you have no preference, rustc is the friendliest first project. If you want to learn the most about classical compiler engineering, LLVM. If you want to land patches on actual systems software in production decades from now, GCC.

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

## Find an issue to start with

### LLVM

LLVM's issue tracker is at <https://github.com/llvm/llvm-project/issues>. Filter by the `good first issue` label. The tracker also accepts the `beginner` keyword on bugzilla.llvm.org, which mirrors into GitHub.

Beginner-friendly categories: documentation patches, small optimiser bugs, missing diagnostics, target-specific instruction-selection rules.

### rustc

rust-lang/rust has explicit beginner labels: `E-easy`, `E-mentor` (for issues with a designated mentor), and `E-help-wanted`. There is also <https://triage.rust-lang.org/> which surfaces actionable issues by area.

Beginner-friendly categories: diagnostic-message rewordings (the `A-diagnostics` label), small lint extensions, MIR-pass refinements, parser edge cases.

### GCC

GCC tracks bugs in Bugzilla at <https://gcc.gnu.org/bugzilla/>. There is no "good first issue" tag in the Rust/LLVM sense, but `Severity: enhancement` tends to surface small improvements. The mailing list <gcc@gcc.gnu.org> is the place to ask.

Beginner-friendly categories: target-specific code generation bugs, especially on less-tested targets; documentation; tooling around the testsuite.

## Learn the review process

The three compilers have different review cultures.

**LLVM** reviews patches via GitHub pull requests (the move from Phabricator was completed in 2024). Reviewers are subscribed by area; you tag the right ones based on the file paths you touched. Every patch needs at least one approval before merge. Style is enforced by clang-format. Tests live next to the changed code; lit-based regression tests in `llvm/test/` are the dominant kind.

**rustc** reviews on GitHub. Every PR needs an `r=<reviewer>` comment from a designated reviewer; bors is the merge bot. Mentored issues come with a designated `r?@<reviewer>` already assigned. The dev guide has a whole chapter on the review process. Stable, beta, and nightly channels mean some changes need explicit team approval to backport.

**GCC** reviews patches by mailing list. You send a patch as a `git format-patch` email to <gcc-patches@gcc.gnu.org>, with a description that explains the why. A maintainer responds with feedback or "OK to commit" eventually. The cadence is slower than GitHub-PR projects; build patience into your expectations. Patches must include a Changelog entry and conform to the GNU coding style.

## Write the change like the project would

Before submitting, confirm you have:

- A test that fails before your change and passes after. All three projects require this in some form.
- A change that conforms to the project's coding style (clang-format for LLVM, rustfmt for rustc, the GNU style for GCC).
- A commit message that explains the *why*. The diff shows the *what*.
- A clear scope. Each change does one thing. Resist the temptation to also fix the unrelated thing you noticed.

These habits are the same ones our [AGENTS.md](../AGENTS.md) imposes for this project. The discipline transfers directly.

## Read code before you write it

The single highest-value habit when getting started is reading the existing source for the area you intend to change. For each project:

- LLVM: read several existing passes in the directory you intend to add to. Study how they handle their data, write tests, name their files.
- rustc: read the rustc-dev-guide chapter for the area, then read the corresponding `compiler/rustc_*/` crate. The crate-level READMEs are short and to the point.
- GCC: read the relevant `gcc/doc/` chapter, then the existing functions in the file you are about to modify. Pay attention to the style of comments and macro use; GCC has more idiosyncratic conventions than the C++ projects.

This step is not optional. Reading half a dozen similar changes makes the first contribution roughly free; skipping it usually costs a long review thread.

## Realistic expectations

A first patch typically takes:

- An afternoon to identify a candidate issue.
- A day to set up the build and reproduce the bug.
- A day to implement the fix.
- A few days of review back-and-forth.
- A handful of minor revisions to land.

A week is a normal first-contribution timeline. Two weeks is also normal. A month is fine. The contributors who struggle most are the ones who expected an hour.

## Where to go next

- [llvm-overview.md](llvm-overview.md), [gcc-overview.md](gcc-overview.md), [rustc-overview.md](rustc-overview.md): structural orientation for each compiler.
- [from-intercal-to-real-compilers.md](from-intercal-to-real-compilers.md): the conceptual bridge from this book's content to production-compiler work.
- [further-reading.md](further-reading.md): books and papers that go deeper into specific areas.
