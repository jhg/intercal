# Further reading

An annotated bibliography of external resources that pair well with this repository. The resources are grouped by topic. For each, the annotation explains what the resource teaches, how it complements our docs, and which chapter here it pairs with most naturally.

All entries listed are free to read online or widely available in libraries. Priced texts are noted accordingly.

## Comprehensive compiler-construction books, free online

- *Crafting Interpreters* by Robert Nystrom. Available at https://craftinginterpreters.com. A hands-on introduction to scanning, parsing, and evaluation, written against a small scripting language called Lox. The Java half of the book walks through a tree-walk interpreter, the C half walks through a bytecode VM. Pairs with our [pipeline.md](pipeline.md) and [lexing-and-parsing.md](lexing-and-parsing.md). The book's deliberate choice to hand-write everything rather than use generators matches the style of this project.

- *Introduction to Compilers and Language Design* by Douglas Thain, University of Notre Dame. Available at https://dthain.github.io/books/compiler/. A single-semester textbook that walks through a full compiler for a C-like language targeting real assembly. Broader than *Crafting Interpreters* in coverage, includes optimisation and register allocation, and closer in tone to a university syllabus. Pairs with [code-generation.md](code-generation.md) and [platforms.md](platforms.md).

- *Essentials of Compilation* by Jeremy G. Siek. Available in both Python and Racket editions at https://github.com/IUCompilerCourse. An incremental approach: start with a tiny arithmetic language and grow it, chapter by chapter, into a realistic language. Emphasises the intermediate-representation design decisions that our no-IR approach skips. Pairs with [self-hosting.md](self-hosting.md) if the reader is considering adding an IR later.

- *Basics of Compiler Design* by Torben Æ. Mogensen. Available at http://hjemmesider.diku.dk/~torbenm/Basics/. A compact, theory-forward textbook used at the University of Copenhagen. Stronger on formal grammar, parsing tables, and attribute grammars than the implementation-focused books above. Pairs with [appendix-grammar.md](appendix-grammar.md) and [semantic-analysis.md](semantic-analysis.md).

- *Let's Build a Compiler* by Jack Crenshaw. Available at https://compilers.iecc.com/crenshaw/. A 1988–1995 series of articles written in a conversational style, building a compiler in Turbo Pascal that emits Motorola 68000 assembly. Valuable for its "keep it simple" philosophy, which maps directly onto our own single-pass no-IR design. Pairs with [code-generation.md](code-generation.md).

## Classic compiler textbooks (print)

- *Compilers: Principles, Techniques, and Tools*, known as the Dragon Book, by Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman (Pearson, 2nd edition 2006). The canonical reference. Widely cited, dense, comprehensive. Covers topics our docs touch only lightly: LR parsing, SSA, register allocation, data-flow analysis. A legal reading copy is sometimes available at https://faculty.sist.shanghaitech.edu.cn/faculty/songfu/cav/Dragon-book.pdf (unofficial mirror). Pairs with the whole of our docs; serves as the authoritative academic reference.

- *Engineering a Compiler* by Keith D. Cooper and Linda Torczon (Morgan Kaufmann, 3rd edition 2023). Emphasises the engineering side more than the Dragon Book: SSA is treated as a central IR, and the back-end chapters are unusually thorough. Good companion for readers who intend to add an IR and optimisation passes to our compiler.

- *Modern Compiler Implementation* by Andrew W. Appel, with ML, Java, and C editions (Cambridge University Press). The tiger-compiler book. A tutorial-style walkthrough of a full compiler implementation, with a well-designed incremental structure. Pairs with [self-hosting.md](self-hosting.md).

## Bootstrapping and self-hosting specifically

- "Bootstrapping and Metacompiling" by Tom Mewett. Available at https://tmewett.com/bootstrapping-metacompiling/. A short blog-length piece that lays out the two strategies for self-hosting (external language bridge, existing self-hosted compiler extension) with clear diagrams. Pairs with [self-hosting.md](self-hosting.md).

- "Reflections on Trusting Trust" by Ken Thompson. Turing Award lecture, 1984. Available at https://www.cs.cmu.edu/~rdriley/487/papers/Thompson_1984_ReflectionsonTrustingTrust.pdf. The canonical discussion of the trust implications of a self-hosted compiler: a malicious compiler can perpetuate itself through generations of self-compilation. Worth reading even though our compiler is too small to be a realistic vehicle for such an attack.

- The Onramp project at https://github.com/ludocode/onramp. A portable self-bootstrapping C compiler designed to build itself on systems that lack any pre-existing C compiler. Different philosophy from ours, minimal subset first, grow outward, but the same family of problem. Pairs with [self-hosting.md](self-hosting.md).

- The shecc project at https://github.com/sysprog21/shecc. A self-hosting educational C compiler targeting ARM32 and RISC-V. Similar educational ambitions to this repository but for a real language. Good comparison point.

## Per-compiler resources (Part VII deep dives)

### LLVM
- LLVM Language Reference Manual (LangRef.rst), the IR specification, at <https://llvm.org/docs/LangRef.html>.
- "The Architecture of Open Source Applications: LLVM" by Chris Lattner at <https://aosabook.org/en/v1/llvm.html>.
- LLVM Developer Meetings (twice yearly, on YouTube) for talks on every part of the project.
- LLVM Weekly newsletter at <https://llvmweekly.org/>.
- The Clang Docs at <https://clang.llvm.org/docs/> for the reference C/C++ frontend.

### GCC
- GCC Internals manual at <https://gcc.gnu.org/onlinedocs/gccint/>. Covers GENERIC, GIMPLE, RTL.
- "An Introduction to GCC" by Brian J. Gough, free at <https://nongnu.askapache.com/gcc-intro/>.
- The GCC Summit proceedings (2003-2010) for retrospective architectural papers.
- GCC mailing list archives at <https://gcc.gnu.org/lists.html>.

### rustc
- The [rustc-dev-guide](https://rustc-dev-guide.rust-lang.org/), the canonical reference for rustc internals.
- *The Rustonomicon* at <https://doc.rust-lang.org/nomicon/> for unsafe Rust details the compiler enforces.
- Niko Matsakis's blog at <https://smallcultfollowing.com/babysteps/> for design history of the borrow checker, NLL, and Polonius.
- Rust Internals forum at <https://internals.rust-lang.org/>.
- "Rust Compiler Performance" at <https://perf.rust-lang.org/> for tracking compile-time regressions.

### Go (gc)
- The Go internals series at <https://internals-for-interns.com/posts/understanding-go-runtime/> walks the runtime piece by piece. Pairs with our [runtime.md](runtime.md).
- Sazak's Go internals series at <https://sazak.io/series/go-internals> covers the SSA backend and walk pass in detail.
- The community-maintained <https://github.com/emluque/golang-internals-resources> indexes most Go internals material.
- Russ Cox's blog at <https://research.swtch.com/> for original design notes.
- The Go assembly documentation at <https://go.dev/doc/asm>.

### GHC (Haskell)
- "The Implementation of Functional Programming Languages" by Simon Peyton Jones (1987), free at <https://www.microsoft.com/en-us/research/publication/the-implementation-of-functional-programming-languages/>.
- "Implementing Lazy Functional Languages on Stock Hardware: The Spineless Tagless G-Machine" (Peyton Jones 1992), the canonical STG reference.
- "OutsideIn(X): Modular type inference with local assumptions" (Vytiniotis et al. 2011) for the type-checker algorithm.
- The GHC Commentary at <https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary>.
- "Trees that Grow" (Najd and Peyton Jones 2017) for the HsSyn AST design.

### OCaml
- The OCaml manual at <https://ocaml.org/manual>.
- *Real World OCaml* by Yaron Minsky, Anil Madhavapeddy, Jason Hickey, free at <https://dev.realworldocaml.org/>.
- Xavier Leroy's papers at <https://xavierleroy.org/publi/>.
- "The ZINC Experiment: An Economical Implementation of the ML Language" (Leroy 1990) for the bytecode VM.
- "Linear Scan Register Allocation" (Poletto and Sarkar 1999), implemented in `asmcomp/linscan.ml`.

### Cranelift
- Cranelift documentation in the wasmtime repo at <https://github.com/bytecodealliance/wasmtime/tree/main/cranelift/docs>.
- Chris Fallin's blog at <https://cfallin.org/> for design notes on regalloc2 and ISLE.
- "Simple and Efficient Construction of Static Single Assignment Form" (Braun et al., CC 2013) for the on-the-fly SSA construction algorithm.
- Bytecode Alliance Zulip at <https://bytecodealliance.zulipchat.com/>.

### Zig
- The Zig language reference at <https://ziglang.org/documentation/master/>.
- Andrew Kelley's blog at <https://andrewkelley.me/> for the bootstrap and self-hosted backend stories.
- Zig Software Foundation developer notes on YouTube.
- Zig source documentation in `src/Sema.zig` and surrounding files.

### Swift
- Swift compiler documentation at <https://swift.org/swift-compiler/>.
- The SIL specification in `docs/SIL.rst` of the swift repo.
- Apple WWDC sessions on the Swift compiler.
- Swift evolution proposals at <https://github.com/apple/swift-evolution>.
- *Swift Intermediate Language: A High-Level IR to Complement LLVM* by Chris Lattner.

### V8
- V8 design docs at <https://v8.dev/docs/>.
- V8 blog at <https://v8.dev/blog>, particularly the posts on Sparkplug, Maglev, and Orinoco.
- Mathias Bynens's articles at <https://mathiasbynens.be/notes/> on V8 internals.
- Cliff Click's papers on sea of nodes and HotSpot's C2.

## Specific techniques

- "Grammar: The language of languages" by Matt Might. Available at https://matt.might.net/articles/grammars-bnf-ebnf/. A clear, example-rich survey of BNF, EBNF, ABNF, and their uses. Pairs with [appendix-grammar.md](appendix-grammar.md).

- The Wikipedia article on recursive descent parsing at https://en.wikipedia.org/wiki/Recursive_descent_parser. Includes a complete implementation of a recursive-descent parser for Wirth's PL/0 language in C, which is a useful sanity check for somebody reading our `parse_expr`. Pairs with [lexing-and-parsing.md](lexing-and-parsing.md).

- The Wikipedia article on calling conventions at https://en.wikipedia.org/wiki/Calling_convention. Covers the ABI contract for every major architecture we target and several we do not. Pairs with [platforms.md](platforms.md).

- The OSDev wiki's "Making a Compiler" page at https://wiki.osdev.org/Making_a_Compiler. A brief survey of the compiler anatomy. Overlaps with [map-of-the-compiler.md](map-of-the-compiler.md) from a different angle: OS-development readers coming to compilers often arrive here first.

- CS 6120: Advanced Compilers, Cornell, self-guided edition by Adrian Sampson. Available at https://www.cs.cornell.edu/courses/cs6120/2023fa/self-guided/. An introduction to modern compiler optimisation techniques. SSA, dataflow analysis, loop transformations. Useful for the reader who wants to see where a compiler goes *after* the basic pipeline this repository implements.

## INTERCAL resources

- The INTERCAL-72 reference manual. The original language specification by Donald Woods and James Lyon, 1973. Authoritative for the language semantics. Available as a scan at https://3e8.org/pub/intercal.pdf.

- C-INTERCAL documentation at http://catb.org/~esr/intercal/. Maintained by Eric S. Raymond. Covers the C-INTERCAL extensions and some of the interpretation details that inform this compiler without being copied.

- CLC-INTERCAL at https://uilebheist.srht.site/. Maintained by Claudio Calvelli. The source of the Label 666 idea, though we adopt a simpler parameter-passing convention than CLC-INTERCAL's "call by vague resemblance to the last assignment" (see [666.md](666.md)).

- The Esolang wiki entry for INTERCAL at https://esolangs.org/wiki/INTERCAL. A good encyclopedic overview, with pointers to related esoteric languages.

- "INTERCAL: The Language Designed to Mock All Other Languages" by Viswhakarma K, available on DEV.to at https://dev.to/viz-x/intercal-the-language-designed-to-mock-all-other-languages-2dlf. A short, opinionated introduction for somebody entirely new to INTERCAL.

## Executable formats and linking

- The System V Application Binary Interface, multiple architecture supplements. The authoritative definitions of the calling conventions, executable layout, and symbol handling rules for every Unix-like target we support. Relevant volumes:
  - x86-64: https://gitlab.com/x86-psABIs/x86-64-ABI.
  - AArch64: https://github.com/ARM-software/abi-aa.
  Pairs with [platforms.md](platforms.md).

- The Apple Mach-O file format documentation, available in the MachO framework headers and at https://github.com/aidansteele/osx-abi-macho-file-format-reference. The closest thing to a spec for the Mach-O format our macOS binaries use.

- "Linkers and Loaders" by John R. Levine (Morgan Kaufmann, 1999). The standard treatment of how the system linker glues object files into executables. We do not link manually (we invoke `cc` as a driver), but understanding what it does under the hood illuminates the post-codegen phase.

## Testing, TDD, and differential testing

- "Finding and Understanding Bugs in C Compilers" by Xuejun Yang, Yang Chen, Eric Eide, and John Regehr. PLDI 2011. Available at https://www.flux.utah.edu/download?uid=114. Describes the Csmith fuzzer and the bug findings it produced across GCC and LLVM. The original high-profile demonstration that differential testing is a powerful compiler-verification technique. Pairs with [testing-and-workflow.md](testing-and-workflow.md).

- "Differential Testing of a Verification Framework for Compiler Optimizations" by Brae J. Webb, Ian J. Hayes, and Mark Utting. 2022. https://arxiv.org/abs/2212.01748. An experience paper applying differential testing to GraalVM optimisation correctness. Directly relevant to our pure-vs-native syslib testing pattern.

## Historical and philosophical

- "The Evolution of Lisp" by Guy L. Steele Jr. and Richard P. Gabriel. HOPL-II, 1993. Available at https://www.dreamsongs.com/Files/Hopl2.pdf. Not about INTERCAL, but a beautifully written account of how a language evolves through implementation. The self-hosting arc Steele and Gabriel describe has clear parallels to our own three-phase bootstrap.

- "Growing a Language" by Guy L. Steele Jr. OOPSLA 1998 keynote. Available in transcript form at https://www.cs.virginia.edu/~evans/cs655/readings/steele.pdf. A talk on how a small language grows into a large one through self-definition. Relevant mindset for the stage3 project.

## What to read next, depending on your goal

- **Build a toy compiler for a C-like language.** Start with Thain, then Crenshaw, then Cooper & Torczon.
- **Understand the INTERCAL dialect and why we chose specific tradeoffs.** Read the INTERCAL-72 manual, then our [overview.md](overview.md) and [intercal-primer.md](intercal-primer.md), then [666.md](666.md).
- **Write a self-hosting compiler.** Start with Mewett's essay, Mogensen, then [self-hosting.md](self-hosting.md), then Appel.
- **Contribute to this repository.** Read [AGENTS.md](../AGENTS.md), then [map-of-the-compiler.md](map-of-the-compiler.md), then the chapters relevant to the area you want to modify.
- **Learn classical compiler theory rigorously.** Dragon Book cover-to-cover, then Engineering a Compiler for modern practice.
