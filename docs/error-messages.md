# Error message design

A compiler's error messages shape its usability more than almost any other surface. A correct compiler with hostile diagnostics is an unfriendly tool; an inaccurate compiler with helpful messages is at least debuggable. INTERCAL puts the bar somewhere unusual: the *format* of error messages is part of the language's deliberate joke (codes like `ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE`), but the format does not relieve us of the obligation to make them helpful.

This chapter documents what our error messages look like, how they have improved since the project began, and where they fall short of what modern compiler diagnostics deliver.

## The ICL convention

Every compile-time and runtime error fires a message of the form `ICLnnnI MESSAGE TEXT`, where `nnn` is a three-digit decimal code. The convention dates to the 1972 INTERCAL manual and has been preserved by every subsequent implementation. The codes are part of the language's specification, `ICL079I` is the rude-program error in C-INTERCAL, in CLC-INTERCAL, and in ours.

The text is uppercase by tradition. `PROGRAMMER IS INSUFFICIENTLY POLITE` is the spec text; substitutions are not allowed. This is a constraint our diagnostics inherit and that we honour.

## What our error messages contain today

A typical compile-time error, fired by `die_compile`:

    ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE
        ON THE WAY TO STATEMENT 7 (LABEL (200), SOURCE LINE 12)

Three pieces:

1. The numeric code and uppercase message text from the spec.
2. The statement number where the error fired.
3. The label (if any) of that statement, plus the source line number.

The second and third pieces are project-specific; they did not exist a few months ago. `die_compile` was extended to take an optional statement-index argument, and many call sites now pass it. The result is a diagnostic that points at *some* location in the source, not a Rust-grade caret, but enough that a programmer can find the offending line.

A runtime error, fired by `_rt_error_E*`:

    ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON

Just the code and message; no source location, because the runtime does not have access to the source file. A programmer hits ICL123I and has to grep for NEXT statements to find the loop.

## What modern compilers do

The state of the art for compiler error messages is, by widespread agreement, what Rust's `rustc` started doing around 2016 and what Elm did before it. The Rust diagnostic redesign was led by Niko Matsakis, Yehuda Katz, Aaron Turon, Alex Crichton, and Sophia Turner. Three principles emerged:

- **Spans, not lines.** Every diagnostic carries a span (start byte, end byte, file). The message points at the smallest range that signifies the issue. A wrong type does not blame the whole expression; it blames the operand.
- **Multiple labels per diagnostic.** A primary span gets the main label; secondary spans get supporting labels ("variable defined here", "expected type required by this signature"). The reader sees several locations at once.
- **Suggestions.** When the compiler can plausibly guess the fix ("did you mean `&` instead of `&&`?"), it offers a concrete edit, often as a code-actionable snippet that an IDE can apply with one keystroke.
- **Plain language.** Even the technical messages are written in sentences. `expected type \`u32\`, found type \`String\`` reads naturally; the compiler does not assume the reader has internalised the term-rewriting formalism.

Each of these principles is a research direction, and Rust's actual implementation took years. The infrastructure (`rustc_errors::DiagCtxt`, the `span_*` methods, the JSON-emitter for tooling) is substantial.

## How our diagnostics compare

We are short of Rust on every axis:

- **Spans.** We have a statement number and a source line, but not a column or a byte offset. The unit of localisation is the whole statement.
- **Multiple labels.** Our diagnostics are single-label only. ICL182I (duplicate label) names the duplicate, but does not also point at the original definition.
- **Suggestions.** We never suggest a fix. The user has to read the message text and reason about the cause.
- **Plain language.** The spec mandates baroque uppercase text. `PROGRAMMER IS INSUFFICIENTLY POLITE` is a faithful rendering, but it is also unhelpful to somebody who does not already know the politeness rule. We compensate by linking from the docs (this book) to the meaning.

The gap is reasonable for our use case. We have no IDE integration, no JSON emitter, no users for whom diagnostic latency is critical. The current diagnostics are enough to debug compile failures from the command line.

## Improvements that would be cheap

Several improvements would not require a full rewrite:

- **Column number on the source line.** The lexer's `\x01` separator already tracks statement boundaries; extending it to record byte offsets would let us produce `source.i:12:34` references.
- **Multi-label ICL182I.** When firing the duplicate-label error, also report the index of the previous statement that used the same label. The information is in `label_to_stmt` already; we just do not print it.
- **Suggestions for typos.** Each statement that classified as `UNKNOWN` could be compared against the list of known verbs with edit-distance one or two. A typoed `DO READ OUT .1` (say, `DO REED OUT .1`) could be flagged with a "did you mean READ?" suggestion.
- **Source line printing.** When firing an error, print the full source line and a caret pointing at the statement boundary. `intercalc.sh` would need to keep the original source string around for this to work, which it already does (it is in `SOURCE`).

The cost of each is low; the cost of a full Rust-style diagnostic infrastructure is high. We should pick the cheap improvements and stop.

## Improvements that would be expensive

- **Spans through the parser.** Tracking byte spans for every expression node would require restructuring the parallel-array AST to carry source positions. Not impossible, but invasive.
- **JSON emitter for tooling.** Useful only if there were tools that consumed it. We have none.
- **i18n.** The error messages are in English (uppercase). Translating them is a large effort with no clear audience; INTERCAL programmers are global but small.

These are not on the roadmap.

## How `die_compile` was extended

Originally `die_compile` took two arguments: code and message. Adding the third (statement index for context) was a single-commit change:

```zsh
die_compile() {
  local code=$1
  local msg=$2
  local ctx_idx="${3:-}"
  if [[ -z "$ctx_idx" && -n "${i:-}" && "$i" =~ '^[0-9]+$' ]]; then
    ctx_idx="$i"
  fi
  echo "ICL${code}I ${msg}" >&2
  if [[ -n "$ctx_idx" && -n "${stmt_type[$ctx_idx]:-}" ]]; then
    local lbl="${stmt_label[$ctx_idx]:-}"
    local line="${stmt_source_line[$ctx_idx]:-?}"
    if [[ -n "$lbl" ]]; then
      echo "    ON THE WAY TO STATEMENT $ctx_idx (LABEL ($lbl), SOURCE LINE $line)" >&2
    else
      echo "    ON THE WAY TO STATEMENT $ctx_idx (SOURCE LINE $line)" >&2
    fi
  fi
  exit 1
}
```

The context-detection heuristic, if no third arg is passed, look for an `i` variable in the caller's scope, lets old call sites keep working without modification while new ones get the context for free. It is a small example of the kind of incremental usability work that a compiler benefits from.

## The runtime side

Runtime errors do not have access to the source file, so they cannot print source lines. They could, in principle, print the statement number that fired the error, the codegen knows which statement is being executed at the call site. This would require emitting the statement index as a data argument to every `_rt_error_*` call, which doubles the size of error-emitting code. We have not done it.

A useful intermediate would be a `--debug` flag that emits per-statement labels into the binary and a runtime hook that prints the active statement on error. The cost is binary size and a small startup penalty; the benefit is much better runtime diagnostics. Worth considering for a future release.

## Exercises

1. Construct a program that fires `ICL182I` (duplicate label). What information does the current diagnostic give you? What would a multi-label version look like?
2. Run `intercalc.sh --diagnose` on `tests/test_hello.i`. The output is a different kind of diagnostic, informational rather than error. Compare its format to the error format. What design choices differ?
3. The lexer collapses whitespace and tracks no source positions. If we wanted line:column references in diagnostics, what data would `tokenize` need to record per statement?
4. Pick one of the cheap improvements listed above (e.g. typo suggestions for unknown verbs). Sketch the implementation in zsh. How many lines?
5. Compare `ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE` with what Rust would say for an analogous offence (e.g. a `#[deny(missing_docs)]` violation). Which is more helpful? Which is more memorable?

## Next reading

- [debugging.md](debugging.md): how to use the current diagnostics in practice.
- [semantic-analysis.md](semantic-analysis.md): where most compile-time errors fire from.
- [runtime.md](runtime.md): the runtime-error catalogue.
