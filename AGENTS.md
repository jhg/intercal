# Intercal compiler

The first compilation of this compiler requires a intercal compiler in other stack, C, assembler, whatever.

## Doc

This requires a GitHub workflow to compile itself using previous released compiler, to release next version.

The intercal language documentation is at:
- http://catb.org/~esr/intercal/
- http://catb.org/~esr/intercal/THEORY.html
- http://catb.org/~esr/intercal/ick.htm
- http://catb.org/~esr/intercal/paper.html
- https://3e8.org/pub/intercal.pdf

Latest distribution download to compile first release with a intercal compiler:
- http://catb.org/~esr/intercal/intercal-0.30.tar.gz

Other doc to review:
- https://en.wikipedia.org/wiki/INTERCAL
- https://dev.to/viz-x/intercal-the-language-designed-to-mock-all-other-languages-2dlf
- https://earthly.dev/blog/intercal-yaml-and-other-horrible-programming-languages/
- https://en.wikipedia.org/wiki/COMEFROM#Hardware_implementation

## Roadmap

[ ] Document in AGENTS.md useful information about how to develop using intercal to know also what the compiler must do
[ ] Create a basic compiler with basic support to compile itself
[ ] Download an intercal compiler for first compilation and check if compiled executable can compile itself correctly and that one can work properly compiling itself again
[ ] Upload that first executable as a release to GitHub
[ ] Add a GitHub workflow that can download latest release binary to use it to compile the new version, then use the new version to compile itself, and release the new version
[ ] Improve the compiler and release it using the GitHub workflow

## Development

- Does NOT use gh cli, it is not available
- Does NOT use bold `**` when write markdown
- Request any additional detail you need or help/actions you need from user
- Does NOT use code from documentation or examples to avoid license conflicts
- Does NOT use text from documentation or examples to avoid license conflicts

### Files and conventions

- `CLAUDE.md` is a symlink to `AGENTS.md` — always edit `AGENTS.md`, never `CLAUDE.md` directly
- `TODO.md` at root is a working notes file for Claude between iterations (not project docs)

### Examples that could be a test of this compiler, compiling and executing it

- https://github.com/leachim6/hello-world/blob/main/i/Intercal.i
- https://github.com/lazy-ninja/HELLO-INTERCAL/blob/master/ickhello.i
- http://progopedia.com/example/hello-world/259/

## Architecture

This compiler compiles INTERCAL source directly to native executable binary. It does NOT transpile to C or any other intermediate language. Unlike C-INTERCAL (ick), which goes through .i -> .c -> .o -> executable, this compiler goes directly from .i to executable.

### Compilation pipeline

- Input: `.i` source files (or `.3i` to `.7i` for bases 3-7)
- Output: native executable binary (no extension on Linux/macOS, `.exe` on Windows)
- No intermediate language files are generated (no .c, no .rs, no .o)

### Fallback: Rust as intermediate language

If compiling directly to executable turns out to be infeasible (missing linker, too complex for bootstrap), the fallback is to transpile to Rust and use rustc as backend. This is a last resort and should be avoided if possible.

### Linking strategy

The compiler needs a linker to produce final executables. Available tools:
- System linker: `ld` (Apple ld on macOS, GNU ld on Linux)
- System C compiler as linker driver: `cc` (can invoke as `cc -o output file.o`)
- Rust-bundled LLD linker (available via Rust toolchain):
  - `rust-lld` — generic LLD entry point
  - `ld.lld` — ELF (Linux)
  - `ld64.lld` — Mach-O (macOS)
  - `lld-link` — COFF/PE (Windows)
  - Located at: `$(rustc --print sysroot)/lib/rustlib/<target>/bin/`

The compiler should generate machine code (or assembled object files) and then invoke one of these linkers. Prefer the system linker (`cc` as driver) for simplicity. The Rust-bundled LLD is a backup if no system linker is available.

### Source file extensions

- `.i` — INTERCAL source (base 2)
- `.3i` to `.7i` — INTERCAL source for bases 3 to 7

## Additional details

<... to be filled ...>
