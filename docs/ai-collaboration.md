# Working on this repository with an AI agent

This chapter is for the human who wants to use an AI coding assistant on this repository, and for the AI agent itself. The primary guide for any contributor — human or AI — is `AGENTS.md` in the repository root. That file is the authoritative contract: how to run tests, how to structure commits, what the TDD workflow looks like, which language pitfalls apply to which platform. What follows here is the shorter, compiler-specific briefing that assumes `AGENTS.md` will be consulted whenever specifics are needed.

## Why this matters

This project's design is unusual along several dimensions that AI agents, trained on conventional codebases, tend to get wrong:

- The source language is INTERCAL. Pattern-matching against C, Python, or Rust idioms produces misleading suggestions.
- The bootstrap compiler is a 1825-line zsh script, not a Python or Rust program. Agents often try to introduce tooling from other ecosystems.
- There is no intermediate representation. Agents trained on LLVM-style architectures often suggest adding one.
- The platform differences are syntactic, not semantic. An agent that sees "ARM64 assembly" and assumes it can be copy-pasted from a Linux source to a macOS source will break things.
- The self-hosting goal is a fixpoint, not a feature flag. An agent that makes a change that breaks the bootstrap compiler has broken everything downstream.

The right mental model is closer to a 1970s compiler than to a modern LLVM front-end. The shortcuts a modern toolchain provides are not available, and when they are proposed they usually produce subtle breakage.

## The non-negotiable rules

From `AGENTS.md`, summarised:

- Before modifying the compiler, syslib, or runtime, add a failing test that captures the intended behaviour.
- Run `zsh tests/run_tests.sh` locally before every commit. For self-hosted changes run `zsh tests/run_self_tests.sh` too.
- One sub-stage per commit during stage3 development; each commit is green on all three platforms.
- Never edit `CLAUDE.md` directly — it is a symlink to `AGENTS.md`.
- Never skip git hooks (`--no-verify`) without explicit permission.
- Never commit broken code. If a commit fails tests, fix it or revert; do not amend a broken commit's predecessor.
- Never delegate understanding to a sub-agent. Sub-agents are for parallel research, not for one-off edits to `intercalc.sh` or the runtime assembly.

These rules exist because past violations have caused real regressions. The TDD rule in particular is the project's primary defence against the class of bugs that are easy to write and hard to reproduce.

## What an agent is good for here

- Broad searches across the codebase (find every place `,65535` is written, find every `_rt_error_*` call site, enumerate all TODOs).
- Parallel research (platform-specific assembly pitfalls vs cross-platform pitfalls, differential-testing techniques vs traditional golden-output testing).
- Drafting documentation — the kind of editorial work this directory represents.
- Proposing test cases from a natural-language description of a bug.
- Reviewing a diff for consistency with the rest of the codebase.

## What an agent is not good for here

- Editing `intercalc.sh`, any `codegen_*` function, or the runtime assembly files without a human reviewing the diff line by line. The cost of a miscompilation is one or more platforms failing CI after a push; the cost of a subtle miscompilation is undetected and potentially intermittent.
- Editing `compiler.i` or `stage3.i` without a matching failing-then-passing test. The risk of introducing a regression that only surfaces during the fixpoint test is high.
- Running tests. Tests are run by the human so the output is visible. An agent claiming "all tests pass" without showing the actual output is a stated outcome, not a verified one.
- Making commits. The human commits so that the commit message and staged files are reviewed before they become permanent.

## How to brief an agent effectively

The pattern that works, based on the experience documented in `AGENTS.md` and the memory files:

1. State the problem in one or two sentences, citing the relevant source files and line numbers.
2. Describe what you have already tried and ruled out.
3. List the constraints the agent must respect (platform compatibility, byte-exact output vs bootstrap, the TDD rule).
4. Ask for something concrete: a diff, a test, a paragraph of prose, a list of files to inspect.
5. Set a response-length bound if the output should be compact.

A poorly briefed agent produces generic, middle-of-the-road answers. A well-briefed agent produces targeted work.

## Useful memory patterns

The repository's `memory/` directory (private to each user) stores per-user notes that persist across sessions. The general convention established in this project:

- `memory/project_status.md` — what is done, what is next, phase tracking.
- `memory/architecture.md` — the current compiler architecture, per-platform.
- `memory/bugs_learned.md` — critical bugs and the lessons from them.

These files are not committed to the repository, by design. They hold the agent's running understanding of the project, which would be noise for another human reading the history.

The `TODO.md` at the repository root is different: it is a working notes file between Claude sessions, committed to the tree. It is intentionally informal.

## Repository-specific vocabulary for agent prompts

Words that mean specific things in this project and should not be interpreted through their general software-engineering meaning:

- *Bootstrap* — the shell-script compiler `src/bootstrap/intercalc.sh`, the chispa primigenea. Not the CI concept, not the OS-loading concept.
- *Self-hosted* — compiled by `intercal_core`, itself produced from `src/compiler/compiler.i`. Specifically not the bootstrap path.
- *Fixpoint* — the property that gen2 and gen3 of the self-hosting process produce byte-identical assembly.
- *Template* — a pre-generated assembly file under `src/compiler/templates/`. Not a Jinja template or a C++ template.
- *Runtime* — the hand-written platform-specific assembly under `src/runtime/`. Not a Python runtime, not the JVM.
- *Pure syslib* — the INTERCAL-language implementation of labels 1000–1999 in `src/syslib/syslib.i`. The `--pure-syslib` flag makes the compiler use it instead of the native assembly version.

## The commit message convention

From the last ten commits on `main`:

- `Phase N.M Stage X.Y: short description` for planned-roadmap work.
- `docs: subject` for documentation-only changes.
- `Fix <area>: short description` for bug fixes.
- Body describes the *why* rather than the *what*, since the diff covers the what.
- Every commit ends with the Co-Authored-By line for the AI that participated.

Agents drafting commit messages should match this style.

## When to ask the human for confirmation

Auto-mode or not, some actions warrant a pause:

- Any `git push --force`, `git reset --hard`, `rm -rf`, or operation that destroys uncommitted work.
- Any change to `release.yml`, `ci.yml`, or `.githooks/` that alters the project's quality gates.
- Any change that modifies the template manifest without a matching change to the templates themselves.
- Any deletion of a test case or a `.i` fixture.
- Any change to `LICENSE`, `CODE_OF_CONDUCT.md`, or `SECURITY.md`.

The rule of thumb from `AGENTS.md`: the cost of pausing is low; the cost of an unwanted destructive action is high.

## Reading order for a fresh agent session

1. `AGENTS.md` — the contract.
2. `README.md` — what the repository is and how to build it.
3. `docs/overview.md` — why it is shaped this way.
4. `docs/map-of-the-compiler.md` — where to find things.
5. The phase chapters, as needed for the task at hand.

An agent that starts with the first three files and consults the rest on demand is operating correctly.
