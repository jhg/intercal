# Lexer theory

The lexer in `src/bootstrap/intercalc.sh` is 194 lines of ad-hoc zsh. It works by inspection: read a character, decide which token is being accumulated, continue. A reader who approaches it expecting the machinery of Flex or a DFA-generation tool will find nothing of the sort. This chapter places our hand-written lexer in the theoretical framing that compiler-construction textbooks use, and argues that the ad-hoc structure is more disciplined than it looks.

## Regular languages, in one paragraph

A regular language is a set of strings that can be recognised by a finite-state automaton. Given an alphabet (the characters the language uses) and a finite set of states with transitions between them on each character, an FSA either lands in an accepting state at the end of the input or it does not. Regular languages are the simplest class in the Chomsky hierarchy — simpler than context-free (which needs a stack) or context-sensitive (which needs a tape).

Every sane programming language's token structure is regular. Identifiers, numbers, keywords, punctuation: each can be recognised by a small FSA. A lexer is, at its theoretical core, a collection of FSAs run in parallel or union.

## INTERCAL's token language

The tokens our lexer produces are:

- Verb keywords: `DO`, `PLEASE`, `DON'T`, `NOT`, `N'T`.
- Statement-body keywords: `NEXT`, `RESUME`, `FORGET`, `ABSTAIN`, `REINSTATE`, `FROM`, `IGNORE`, `REMEMBER`, `STASH`, `RETRIEVE`, `READ`, `OUT`, `WRITE`, `IN`, `COME`, `GIVE`, `UP`, `SUB`.
- Gerunds: `CALCULATING`, `NEXTING`, etc. (treated as statement-body keywords).
- Variable prefixes: `.`, `:`, `,`, `;`.
- Constant prefix: `#`.
- Operators: `$`, `~`, `&`, `V`, `?`.
- Grouping: `'`, `"`.
- Punctuation: `(`, `)`, `<-`, `%`, `+`.
- Numbers: sequences of decimal digits.
- Whitespace: any run of spaces, tabs, newlines.

Each of these is recognisable by a small FSA. The union of all such FSAs is still a regular language, so the theoretical tool for recognising them simultaneously is still a single DFA (deterministic finite automaton).

What distinguishes INTERCAL's token language from C's or Python's is essentially two quirks:

1. `DON'T` must be one token, not `DO` + `N'T`. This is a direct consequence of the language specification: `DON'T` is a contraction of `DO` + `NOT`, and the contracted form has no compositional interpretation.
2. Keywords are whole words surrounded by whitespace. `READOUT` is not `READ OUT`. This is unusual — most languages accept both forms of composite keywords — and forces the lexer to check for the space between.

Both quirks are handled with trivial special-case code in our lexer. Neither requires departing from the regular-language model.

## DFA vs NFA vs ad-hoc code

Three ways to recognise a regular language:

- **NFA.** Non-deterministic finite automaton. Allows ε-transitions and multiple transitions on the same character. Easy to construct from a regular expression; slower to run because of the backtracking.
- **DFA.** Deterministic finite automaton. Every state has exactly one transition per character. Fast to run (constant-time per character) but potentially exponential in size compared to the equivalent NFA.
- **Ad-hoc code.** A hand-written recogniser, typically using a `while` loop and a switch-like construct, that implicitly encodes a DFA.

Flex and similar lexer generators take regular expressions, build NFAs, convert to DFAs, minimise the DFAs, and emit C code that runs them. The resulting lexer is fast and correct by construction. The cost is that the generated code is opaque: understanding it requires understanding the generator.

Our lexer is ad-hoc code. We chose this for the same reason *Crafting Interpreters* does: the token language is small enough to fit comfortably in a few hundred lines of hand-written code, and the result is far easier to read and modify than a generator-produced output would be.

The tradeoff is loose: a bug in hand-written code is fixed by editing the code; a bug in the grammar of a generator-based lexer requires understanding both the grammar and the generator's conventions.

## Why we get away without a full DFA

A proper DFA for INTERCAL's tokens would be a finite-but-nontrivial state machine. We get away without building it explicitly because the token language is well-behaved:

- **Keywords start at whitespace boundaries.** Our lexer can skip whitespace, read the next contiguous alphanumeric run, and compare against a short list of keywords. No per-character state is required between tokens.
- **No ambiguity between token classes.** `#5` is always a constant, never a variable, because `#` is never used as a variable prefix. `.5` is always a variable, never a constant. The first character of every token unambiguously determines its class.
- **Statement boundaries are explicit.** Verb keywords (`DO`, `PLEASE`, `DON'T`) are the only statement starters. When we see one, the previous statement is complete.

Any ambiguity that would have forced a real DFA does not arise in the token grammar. The closest we come is in `DO` vs `DON'T`: after reading `DO`, the lexer peeks at the next character to decide whether to consume `N'T` as part of the same token. This is a one-character lookahead, well within what ad-hoc code can handle.

## The `DON'T NOTE` saga as a lexer-theory worked example

One of the earliest compiler regressions in this project was a `DON'T NOTE` bug. The sequence of events:

1. The lexer originally treated `DO` and `N'T` as separate tokens, on the grounds that `DON'T` is just syntactic sugar for `DO NOT`.
2. A user program included `DON'T NOTE foo bar baz`. The lexer produced `DO`, `N'T`, `NOTE`, `foo`, `bar`, `baz`.
3. The statement scanner recognised `DO N'T` as a verb with negation and started consuming a statement body.
4. `NOTE foo bar baz` was not a recognised statement keyword, so the whole thing was classified as `UNKNOWN`.
5. The next verb token — whatever came after the `DON'T NOTE` line — was not immediately found, because the lexer kept consuming "body" until it hit a verb.
6. The previous statement's body grew to include the intended next statement. Chaos followed.

The fix was to treat `DON'T` as a single atomic token. The lexer, after seeing `DO`, checks whether `N'T` immediately follows (no space, still part of the same word). If so, emit `DON'T` as one token. If not, emit `DO` alone.

Expressed in FSA terms, this is a minor modification:

```
        space/start
             │
             ▼
           ┌────┐   D    ┌───┐   O    ┌───┐
           │ S0 │──────►│S1 │──────►│S2 │
           └────┘        └───┘       └─┬─┘
                                       │ space or other
                                       ▼
                                     emit DO
                                  ┌────────────┐
                              N'T │
                                  ▼
                             ┌───┐
                             │S3 │
                             └─┬─┘
                               │ space
                               ▼
                          emit DON'T
```

Our lexer does not have a state machine drawn out in this form; the same logic lives as a couple of `if` branches inside the main scanning loop. But the underlying structure is exactly the FSA above.

## What a generator-based lexer would buy us

Very little. The hand-written lexer is ~200 lines, runs in a few milliseconds on a typical source file, and has been modified perhaps five times in the project's history. A generator-based approach would add a dependency (Flex or an equivalent), a build step, and a second file to maintain (the `.l` source).

The real argument for a generator is correctness: an automatically minimised DFA cannot miss a transition, whereas ad-hoc code can. In practice, every correctness bug we have had in the lexer was about the statement-scanning logic (the `DON'T NOTE` case and one other), not about the token recognition per se. A generator would not have caught either.

We do have one protection against ad-hoc bugs: the test suite. Every INTERCAL feature in the test programs exercises a specific token pattern. If the lexer ever mistokenises, at least one test fails.

## The INTERCAL-level lexer

`stage3.i`, the evolving pure-INTERCAL compiler, will eventually contain its own lexer written in INTERCAL. The target layout:

- A top-level loop over `,65535` (the source loaded via Label 666).
- A state variable `.50` tracking what kind of token is being accumulated.
- Output: parallel arrays `,11–,18` holding the same tuples our bootstrap lexer builds (`stmt_label`, `stmt_polite`, ..., `stmt_body`).

The INTERCAL-level lexer will look significantly uglier than the zsh version — INTERCAL has no string type, no dictionaries, no associative arrays — but the underlying algorithm is the same. A stream of input characters, a state machine that accumulates tokens, a boundary detector that emits statements when a verb keyword appears.

## Exercises

1. Draw the FSA for recognising an INTERCAL numeric constant (`#5`, `#123`, `#65535`). How many states does it have?
2. Extend the FSA for `DO` vs `DON'T` to also recognise `NOT` and `N'T` as separate negation tokens after `DO`. How many states does it need now?
3. Suppose we wanted to support a lowercase variant of the language (where `do`, `please`, `don't` are equivalent to the uppercase forms). What minimal change to the lexer would enable this, and why does our current implementation effectively do it already?
4. The `SUB` keyword is recognised during expression parsing, not during tokenisation. What is the cost of this deferral? What would we gain by moving `SUB` into the lexer?
5. Find the line in `intercalc.sh`'s `tokenize()` that distinguishes `DON'T` from `DO N'T`. Rewrite it in a way that collapses the two branches. Does the resulting code make the state machine more explicit or less?

## Next reading

- [lexing-and-parsing.md](lexing-and-parsing.md) — the concrete shape of our lexer and parser.
- [appendix-grammar.md](appendix-grammar.md) — the context-free grammar that parsing targets.
- [self-hosting.md](self-hosting.md) — the INTERCAL-level lexer coming in stage3.
