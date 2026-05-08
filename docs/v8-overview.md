# V8, in shape

V8 is Google's JavaScript and WebAssembly engine, used in Chrome, Node.js, Deno, Electron, Cloudflare Workers, and a long tail of other runtimes. Source at <https://github.com/v8/v8>. It is the only JIT in this Part. Every other compiler we cover is ahead-of-time. The shift from AOT to JIT changes the design of every component, so V8 deserves its own chapter for that reason alone.

The lessons V8 teaches that nothing else does:

- Tiered execution: an interpreter, a baseline JIT, a mid-tier optimising JIT, and a top-tier optimising JIT all coexist for the same code, with hot functions being promoted up the tiers and cold functions running at the lowest tier.
- Speculation and deoptimisation: optimised code is generated under assumptions about runtime behaviour ("this property is always at offset 8", "this variable is always a small integer") that may not hold; when they fail, execution falls back to a lower tier, reconstructing the interpreter's state from the optimiser's.
- Sea-of-Nodes IR: the optimising tier (TurboFan) uses a graph IR where data flow and control flow are unified, an alternative to conventional SSA.
- Hidden classes: V8 makes JavaScript's dynamic objects behave statically, by maintaining a runtime "shape" for each object that consolidates its layout and lookup paths.
- Inline caches: per-call-site type feedback that bridges interpretation and optimisation.

For a reader of this book, V8 is the long-distance cousin to our INTERCAL compiler. Most of the architectural questions we have do not arise in V8 because V8 has no AOT pipeline and no static syscalls; everything is dynamic, on-demand, with the runtime as the dominant context.

## Tiered execution

V8 has four tiers, top to bottom:

1. **TurboFan** (top-tier optimiser, default since 2017): heavyweight, sea-of-nodes IR, deepest optimisation. Targets hot functions.
2. **Maglev** (mid-tier optimiser, since 2023): lighter SSA-based IR, fewer optimisations. Bridges Sparkplug and TurboFan.
3. **Sparkplug** (baseline JIT, since 2021): a near-single-pass machine code generator from bytecode (a brief loop-discovery pre-pass plus a code-emit pass). No IR.
4. **Ignition** (interpreter, shipped 2016, default since 2017): bytecode interpreter, the floor.

A function's execution path:

- First call: the parser produces bytecode. Ignition interprets it. Inline caches collect type feedback.
- After it has been called enough times: Sparkplug compiles the bytecode to machine code in a single pass. The new code runs in place.
- After it has been called significantly more: Maglev produces a mid-tier optimisation, using the IC feedback. Promotion is automatic.
- For sufficiently hot functions: TurboFan does deep optimisation, producing the final tier.

Each tier is a complete code-generation pipeline. They share the bytecode (Ignition's input is also the input to Sparkplug, Maglev, and TurboFan) and the inline-cache state, but they emit independent machine code.

Why four tiers? Because the amortisation curve is steep. Generating optimised code is expensive, and most functions never run enough to recoup the cost. Generating no code (just interpreting) is cheap but slow per execution. Tiering lets V8 spend just enough compilation effort to match each function's actual demand.

## Ignition: the bytecode interpreter

The bytecode for V8 is custom, ~200 opcodes, register-machine flavour. Each function is compiled to a sequence of bytecode instructions where operands name "registers" (slots in a per-frame register file).

The bytecode handlers themselves are written using V8's CodeStubAssembler (CSA), a TurboFan-backed macro assembler, and compiled at build time. A newer DSL, **Torque** (`src/torque/`), now layers on top of CSA and is the recommended way to write builtins, but Ignition predates Torque and uses CSA directly via the InterpreterAssembler subclass.

What Ignition does that an interpreter for a static language might not:

- Maintains the **inline cache** for every operation that involves type-dependent dispatch (property access, arithmetic, function calls). The IC starts uninitialised, transitions to monomorphic on the first call, polymorphic on subsequent different shapes, and megamorphic if the shape variety exceeds a threshold.
- Records type **feedback** in a per-function `FeedbackVector` that the optimising tiers later consume.
- Cooperates with the GC: every register slot is GC-walkable, the interpreter handles allocation triggers and write barriers.

For a reader, Ignition is the most legible production interpreter for a dynamic language. The Torque source for the interpreter's bytecode handlers is much shorter than equivalent hand-written C++.

## Sparkplug: a baseline JIT in one pass

Sparkplug (`src/baseline/`) is the simplest of the JITs. It is a single-pass code generator: walk the bytecode, emit machine code, done.

What it does not have:

- An intermediate representation. Bytecode goes straight to machine code.
- A pass pipeline. There is one pass.
- An optimisation phase. Only minimal patterns.
- A register allocator beyond what the calling convention forces.

What it does have:

- The same stack frame layout as Ignition. Sparkplug-compiled functions can be called from Ignition and vice versa with identical activation records, which simplifies tier transitions.
- Direct emission of bytecode-level inline-cache logic. The IC state is shared with Ignition.
- Fast compilation: roughly two to three orders of magnitude faster than TurboFan, on the order of bytecode-generation cost per the V8 team's own measurements.

The point of Sparkplug is to eliminate Ignition's interpreter overhead (decoding each bytecode, dispatching to a handler) without paying the cost of an optimising compiler. For middle-tier-of-warmness functions, this is the right tradeoff.

The architectural lesson: a baseline JIT can be radically simple and still produce large speedups. Reading Sparkplug source is a fast education in "what is the minimum machine code generation that beats interpretation".

## Maglev: a mid-tier optimising JIT

Maglev (`src/maglev/`) is the newest of V8's tiers, added in 2023. It uses a simpler SSA IR than TurboFan, and fewer optimisation passes.

The Maglev IR is conventional SSA: basic blocks, instructions, phi nodes (or block parameters, depending on the variant). Optimisation passes include type narrowing from feedback, simple constant folding, simple dead-code elimination. Lowering produces machine code through conventional instruction selection.

Why Maglev exists: Sparkplug code is slow, TurboFan compilation is slow. The gap was wide enough that adding a tier in between was worth the engineering effort. Maglev compiles roughly 10x faster than TurboFan and generates code "much faster than Sparkplug" but slower than TurboFan, per the V8 team's own announcement. The tradeoff fills the right slot in the warmth distribution.

For a reader, Maglev is the cleanest example of "optimising compiler, but lighter". Compared to TurboFan, Maglev does less; compared to Sparkplug, Maglev does more. The architectural decisions visible in its source are mostly about budgeting: how much optimisation is worth doing for a given amount of compile time.

## TurboFan: sea of nodes

TurboFan (`src/compiler/`) is the top-tier optimiser. It is the largest and most distinctive piece of V8.

The TurboFan IR is **Sea of Nodes**, a graph IR introduced in Cliff Click's 1995 PhD thesis "Combining Analyses, Combining Optimizations" (Rice University) and used in HotSpot's C2 (Java's top-tier JIT). The sea-of-nodes idea:

- Each operation is a **node** in a graph.
- Edges represent **dependencies** between nodes, of three kinds: data flow ("the value of node A is used by node B"), control flow ("node A executes, then node B can execute"), and effect ("node A's side effect must precede node B's").
- The graph is **not** linear. Many nodes are "floating": they have no fixed position in any basic block. Their position is determined later by the scheduler, based on dependencies.

This is a big departure from traditional SSA. In LLVM's IR, every instruction has a basic block. In sea of nodes, many instructions float free until a final scheduling pass places them. The freedom to float means optimisations do not have to manage block placement; the scheduler does it.

The pipeline through TurboFan:

1. Bytecode + feedback → graph (with inlining decisions guided by feedback).
2. **Typer** (`src/compiler/typer.cc`): each node gets a type from the type lattice, based on feedback and context. Types include `SmallInteger`, `HeapNumber`, `String`, `Object`, more refined subdivisions for known shapes.
3. **Typed lowering** (`src/compiler/typed-optimization.cc`): replace generic operations with type-specialised ones. `JSAdd(x, y)` where both are SmallInteger becomes `Int32Add`.
4. **Simplification**: classical dead-code, constant-fold, GVN, escape analysis, range analysis.
5. **Simplified lowering** (`src/compiler/simplified-lowering.cc`): more lowering toward machine-level.
6. **Machine lowering**: to a target-specific representation.
7. **Instruction selection** (`src/compiler/backend/instruction-selector-<arch>.cc`).
8. **Register allocation**.
9. **Code emission**.

Each phase reads the graph, modifies it, hands it to the next. The graph data structure is mutated in place across phases, with verification passes between them.

For a reader, sea of nodes is conceptually the hardest IR in this Part. It is also the most rewarding once it clicks. The "C2: A Killer Compiler" papers (Cliff Click, various venues) are the canonical introduction.

## Speculation and deoptimisation

V8's optimising tiers (Maglev and TurboFan) generate code under assumptions. Examples:

- "This variable is always SmallInteger": the optimiser emits Int32 arithmetic instead of generic JSAdd.
- "This object's shape is always Map A": the optimiser emits a direct field load at offset 8 instead of going through a property lookup.
- "This function call always targets `f`": the optimiser inlines `f` and emits direct code.

Each assumption is encoded as a **deoptimisation check** in the generated code: a runtime test that, if false, transfers control out of the optimised code and back to the interpreter (or a lower tier).

The deoptimisation flow:

1. The check fails. Execution branches to a "deopt entry" stub.
2. The stub knows how to reconstruct the interpreter's state from the optimised code's register state. This requires a side table generated at compile time, the **deopt table**.
3. The interpreter resumes execution from the bytecode position corresponding to where the deopt happened.
4. The function's optimisation status is downgraded; subsequent calls run lower-tier code, with new feedback, possibly different optimisation later.

There are two kinds of deopt: **eager** (deopt happens immediately when the check fails) and **lazy** (deopt is recorded but execution continues, with the deopt actually firing at a later safe point). Lazy deopt is used when re-execution from the bytecode position is correct; eager deopt is used when continuation in optimised code would produce wrong results.

The deopt machinery is the secret of V8's performance model. Optimised code can be aggressive because deopt is the safety net. The cost of speculation when it succeeds is one branch (the check); the cost when it fails is recompilation, eventually.

For a reader, speculation + deoptimisation is the JIT-specific lesson that has no parallel in AOT compilers. Static compilation must be conservative (every assumption must hold for every input); JIT compilation can be optimistic (every assumption only has to hold for the typical input, with deopt as fallback).

## Inline caches and feedback vectors

The bridge between the interpreter and the optimisers is the inline cache.

An inline cache is a per-call-site mini state machine. Each property access, arithmetic operation, or call site has an IC. The IC records what the operation has seen so far, and dispatches based on that.

Initial state: **uninitialised**. The first time the operation runs, the IC observes the actual operands or shapes and transitions.

Monomorphic: only one shape has been seen. The IC has a fast path for that shape and a slow path for others. The fast path is a few instructions: type check, direct dispatch.

Polymorphic: a few shapes have been seen (default threshold is 4). The IC has fast paths for each, plus a slow fallback.

Megamorphic: many shapes have been seen. The IC gives up on per-shape optimisation; the operation does a generic lookup.

The IC state is recorded in the function's **FeedbackVector**, a per-function side table. The optimising tiers read this vector to decide what to specialise on.

For a reader, inline caches are the canonical mechanism for type-feedback-driven JIT. They were invented for Smalltalk in the 1980s, refined for Self, and brought to JavaScript by the V8 (and SpiderMonkey, JavaScriptCore) authors. Reading the IC machinery in `src/ic/` shows what type feedback for a dynamic language looks like in production.

## Hidden classes (Maps in V8 jargon)

JavaScript objects are dictionaries: keys are strings, values are anything. Naively implemented, every property access is a hash-table lookup. V8's optimisation: track each object's structural shape, and access properties as array indices when the shape is known.

A **Map** (V8's terminology, unrelated to JS's Map type) is a runtime structure describing an object's shape:

- Field offsets (which property is at which slot).
- Inline-property capacity vs out-of-line property storage.
- Constructor lineage.
- Element kind (small integers, doubles, mixed, packed, holey).

When you write `obj.x = 1` in JavaScript, V8 transitions `obj` from its current Map to a new Map describing the layout with `x`. If many objects construct the same way (e.g., from the same constructor function), they end up with the same Map; their property accesses can be specialised to direct field loads at the right offset.

The Map system is V8's mechanism for treating dynamically-typed objects as if they were statically typed. It is not always able to: highly polymorphic code defeats the optimisation. But for typical JavaScript code, it works extraordinarily well.

For a reader, hidden classes are the JavaScript-specific lesson with no direct parallel in static-language compilers. It is the answer to "how do you make a dictionary-shaped object run fast".

## Garbage collector: Orinoco

V8's GC, codenamed Orinoco, is generational and concurrent.

The young generation uses a copying collector with two semi-spaces. New allocations go into the active semi-space; when it fills, live objects are copied to the inactive one and the active becomes inactive.

The old generation uses a mark-sweep collector with optional compaction. Marking can be incremental and concurrent (running on a separate thread alongside JavaScript execution). Sweeping is parallel.

Write barriers: the JIT-generated code emits write barrier code at every pointer store, ensuring the GC knows about cross-generation pointers and concurrent-marking interactions.

The GC has had multiple major rewrites over V8's lifetime, each named (Mark-Sweep-Compact, Concurrent Marker, Orinoco). Each has improved pause times or throughput by a measurable margin. The 2017 Orinoco redesign is documented in V8 blog posts and is the basis for current V8.

For a reader, the GC is one of the cleanest examples of "concurrent algorithms in production". Every detail (write barriers, marker termination, snapshot-at-the-beginning, work-stealing) has been wrestled with in V8.

## Recent additions: speculative inlining for WebAssembly

A 2025 development worth highlighting: bringing the *speculation framework* (deopt + IC-style feedback) into the WASM pipeline. Historically WASM optimisation in V8 was static; without runtime feedback there was nothing to speculate on. Chrome M137 changed that.

V8 now records call targets for indirect calls during Liftoff execution. Then TurboFan, when promoting a function, can speculatively inline up to four targets, with deopt fallback if the assumption breaks. Reported speedups: over 50% on Dart microbenchmarks and 1-8% on real WasmGC apps.

The implication: WebAssembly is no longer a purely-static target in V8. The same speculation/deopt machinery that makes JavaScript fast is now applied to WASM hot code. Browsers are increasingly running WasmGC programs (Dart, Kotlin/Wasm, soon others) where speculative inlining is the difference between competitive and non-competitive performance.

## WebAssembly support: a parallel pipeline

V8 also runs WebAssembly. The pipeline is separate but shares much of the infrastructure.

WASM tiers:

1. **Liftoff**: baseline WASM compiler. Like Sparkplug for JS. Single-pass, fast compilation, modest code quality. The default for first execution.
2. **TurboFan-WASM**: TurboFan re-targeted for WASM. Heavy optimisation. Used for hot WASM functions or full-module optimisation.

Liftoff was added in 2018. The reason is the same as Sparkplug for JavaScript: WASM compile time matters, and Liftoff produces "good enough" code 10x faster than TurboFan.

For a reader, the WASM tier is interesting because WebAssembly is a typed bytecode (no inline caches, no hidden classes, no JavaScript-specific dynamism). The compiler has the structure of a static-language compiler running as a JIT. It is an instructive contrast with the JavaScript path.

## Snapshot serialisation

V8 startup is famously slow; the engine has a lot of state to set up. The mitigation is **snapshots**: the engine pre-builds heap state at engine-build time, serialises it to disk, and deserialises at startup.

The snapshot includes built-in functions, type info for built-in objects, the initial JS context. Loading the snapshot is much faster than reconstructing it; startup goes from hundreds of milliseconds to tens.

Tools: `mksnapshot` (the snapshot builder, runs at V8 build time), `embedded-builtins.cc` (the embedding format).

For a reader, the snapshot mechanism is one of the cleanest examples of trading build complexity for runtime simplicity. Most languages do not bother because they do not have V8's startup cost; the techniques are valuable to know about even if your project never needs them.

## Repo layout

    src/
      ast/                AST data structures (after parsing)
      parsing/            Parser
      interpreter/        Ignition (bytecode interpreter)
      baseline/           Sparkplug (baseline JIT)
      maglev/             Maglev (mid-tier JIT)
      compiler/           TurboFan (top-tier JIT)
        backend/          Per-arch instruction selection, regalloc
        access-info.cc    Property access reasoning
        typer.cc          Type lattice + propagation
        simplified-lowering.cc
      heap/               Orinoco GC
      objects/            Object representations (Maps, fixed arrays, JSArray, ...)
      ic/                 Inline caches and feedback
      runtime/            Runtime functions (called from generated code)
      torque/             Torque DSL compiler
      builtins/           Torque sources for built-ins
      wasm/               WebAssembly support
      snapshot/           Snapshot serialisation tools
      regexp/             RegExp engine (compiles to bytecode)
    test/                 Tests (mjsunit, cctest, unittests, etc.)
    tools/                Profilers, generators, diagnostic tools

The `tools/` directory has a number of useful diagnostics: `--trace-opt` (log optimisation events), `--trace-deopt` (log deoptimisations), `--print-code` (dump machine code), `--print-bytecode` (dump bytecode). Running V8 standalone (`d8`, the standalone shell) with these flags is the easiest way to see what the compiler is actually doing on a given JS source.

## Comparison with other compilers

| Aspect | V8 | LLVM (Clang) | rustc |
|--------|------|--------------|-------|
| Compilation model | JIT, four tiers | AOT, single tier | AOT, single tier |
| IR | Bytecode + Maglev SSA + TurboFan SoN | LLVM IR (single SSA) | HIR/THIR/MIR/LLVM IR |
| Speculation | Yes, with deopt | No | No |
| Type system | JavaScript dynamic + WASM static | Static | Static |
| GC | Yes (Orinoco) | No (host language) | No |
| Codebase | ~2.3M lines C++ | ~10M C++ | ~3M Rust |

V8 is on the JIT side of every comparison. The cost of being on that side: more runtime complexity, harder to debug, harder to reason about peak performance. The benefit: optimisations that depend on runtime behaviour, possible only with a JIT.

## How V8 compares to our INTERCAL compiler

Almost every architectural choice differs. We are AOT, V8 is JIT. We have a static type system (four numeric types), V8 has runtime-typed values. We have no runtime feedback, V8's runtime feedback is the input to its top-tier optimisations. We have no GC, V8 has Orinoco.

The connection is at the conceptual level: both compilers translate source code into machine code. The lessons from V8 about speculation, tiered compilation, and deoptimisation do not transfer directly to our compiler, but they are the right vocabulary for understanding why some compilers are JITs and some are AOTs and what the tradeoffs are.

If we ever wanted to add a JIT mode to our INTERCAL compiler (for instance, an interactive debug session that compiles INTERCAL functions on demand), the relevant techniques would come from V8.

## If you only read five files

For getting oriented in V8 source:

1. `src/compiler/turboshaft/graph.h` and `src/compiler/turboshaft/operations.h`: the new IR (Turboshaft is replacing TurboFan; the JS pipeline migrated 2024-2026).
2. `src/maglev/maglev-graph-builder.cc`: Maglev's IR construction.
3. `src/ic/ic.cc` and `src/ic/handler-configuration.h`: the inline-cache machinery.
4. `src/codegen/code-stub-assembler.cc`: CSA, the assembler-level macro language.
5. `src/compiler/pipeline.cc`: the orchestrator, tier transitions.

## Common contributor gotchas

- V8 has four tiers (Ignition, Sparkplug, Maglev, Turboshaft/TurboFan). A function can deopt back across them. Your "perf bug" may be a tier-up never happening; check `--print-opt-code` and `%GetOptimizationStatus`.
- IC feedback informs Maglev. Breaking the IC slot layout silently regresses optimisation.
- Turboshaft is replacing TurboFan in 2024-2026; the JS pipeline already migrated. Do not write new TurboFan reducers.
- ICs are written in CSA. Edits live in `*.tq` (Torque), not directly in `.cc`.
- `d8` (the standalone shell) runs without snapshot by default; mksnapshot crashes during build are usually due to a CSA assertion.

## Area specialists

- Tobias Tebbi: Turboshaft, Torque.
- Nico Hartmann: Turboshaft, Maglev co-lead.
- Toon Verwaest and Leszek Swirski: Maglev.
- Jakob Kummerow: numeric, BigInt.
- Camillo Bruni: Sparkplug, perf tooling.
- Ross McIlroy: Ignition.

## Notable recent reads

- V8 blog "Land ahoy: leaving the Sea of Nodes" (Turboshaft rationale).
- "Turbolev" series at blog.seokho.dev (2025).
- Maglev launch post at v8.dev/blog/maglev.

## Diagnostic flags worth knowing

- `--trace-turbo`: writes turbo.json for turbolizer.com (a graphical IR explorer).
- `--trace-turbo-graph`, `--trace-maglev-graph-building`, `--trace-maglev-regalloc`: per-IR tracing.
- `--print-maglev-code`: dump generated Maglev code.
- `--trace-ic`: trace inline-cache transitions.
- `--trace-opt`, `--trace-deopt`: trace optimisation tier transitions and deopts.
- `--trace-turbo-reduction`, `--turboshaft-trace-reduction`: trace IR reductions.
- `--allow-natives-syntax`: enables `%DebugPrint`, `%OptimizeFunctionOnNextCall`, `%PrepareFunctionForOptimization` for in-script introspection.

For graphical exploration: feed `--trace-turbo` JSON into <https://v8.github.io/tools/head/turbolizer/> to step through reductions.

## Reading order

A practical path:

1. Read [V8 design docs](https://v8.dev/docs/) for orientation.
2. Read the V8 blog posts on Sparkplug, Maglev, Orinoco at <https://v8.dev/blog>.
3. Browse `src/baseline/` to see the baseline JIT. It is the smallest tier and the most tractable starting point.
4. Read `src/compiler/typer.cc` to see TurboFan's type lattice.
5. Read "Sea of Nodes" (Cliff Click 1995) before diving into TurboFan.
6. Try the diagnostics: install d8, run with `--trace-opt`, see what V8 actually does on a small program.

## How to contribute

V8 uses Gerrit at <https://chromium-review.googlesource.com>. The process is documented at <https://v8.dev/docs/contribute>.

Beginner-friendly categories:

- Bug fixes in less-frequently-touched parts of TurboFan.
- Diagnostic-message improvements.
- Tests in `test/mjsunit/`.
- Improvements to standalone tools (`d8`, profilers).

Build:

    fetch v8
    cd v8
    gn gen out/x64.optdebug --args='is_debug=true is_component_build=true'
    ninja -C out/x64.optdebug

Build setup uses `depot_tools` (Chromium's tool suite). The first build is slow (an hour or so on modern hardware) and downloads many gigabytes of dependencies.

## Where to go next

- The V8 blog at <https://v8.dev/blog>.
- Mathias Bynens's articles at <https://mathiasbynens.be/notes/> on V8 internals.
- Cliff Click's papers on sea of nodes and HotSpot.
- "Crankshaft, Octane, and the V8 Lineage" papers from the V8 team.
- [llvm-overview.md](llvm-overview.md) for the AOT counterpart.
- [from-intercal-to-real-compilers.md](from-intercal-to-real-compilers.md) for the bridge back to this book.
