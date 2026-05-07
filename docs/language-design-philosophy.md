# Language design philosophy: INTERCAL against the canon

C. A. R. Hoare's 1973 keynote *Hints on Programming Language Design* is the canonical short statement of how to design a programming language well. Hoare lays out five principles (simplicity, security, fast translation, efficient code, and readability) and argues that languages should be evaluated against them.

INTERCAL was published one year before Hoare's lecture and sets out, with what was probably playful awareness, to violate every one of his principles deliberately. Reading the two documents side by side is one of the best ways to understand what INTERCAL is doing and why.

## Hoare's five principles

From the 1973 paper, summarised:

1. **Simplicity.** The language and its compiler should be small enough that a competent programmer can hold both in their head. Features should compose orthogonally; corner cases should be eliminated rather than enumerated.
2. **Security.** The compiler should reject programs whose meaning is not well-defined. Type errors, range errors, and uses-before-definition should fail to compile rather than running and misbehaving.
3. **Fast translation.** A compiler should be able to translate a program faster than the programmer can read it. Long compile times are a barrier to the iterate-and-test cycle.
4. **Efficient code.** The translation should produce executables that run reasonably fast. A factor-of-three slowdown over hand-written assembly is acceptable; a factor of a hundred is not.
5. **Readability.** The source should be readable by somebody other than the author. Identifiers, control flow, and data flow should be evident on first reading.

Hoare elaborates each principle and shows how violations produce real costs, debugging time, security holes, productivity losses.

## INTERCAL against the principles

### Simplicity (violated, on purpose)

INTERCAL has fourteen statement types, four variable namespaces, two grouping characters that must alternate, and a politeness rule that operates on the whole program. The grammar is small but the semantics are not orthogonal: the same `READ OUT` does completely different things on a scalar versus an array, and the Turing Text Model algorithm is not derivable from any simpler principle. A competent programmer can hold the spec in their head, but only after deliberate study; the language does not yield to a casual reading.

The violation is deliberate. Simplicity in Hoare's sense, orthogonal features, would defeat the parodic intent.

### Security (variably honoured)

INTERCAL's compile-time security is limited to the politeness rule, the label uniqueness check, and (now) the spark/rabbit-ears nesting check. Everything else is a runtime error. A program that overflows a 16-bit slot, indexes past an array, or RESUMEs an empty NEXT stack will compile cleanly and fail at runtime.

This is partly a constraint of the language (INTERCAL allows abstention, so most checks have to be runtime) and partly a deliberate parodic choice (security in Hoare's sense would require typing, which INTERCAL refuses).

### Fast translation (mixed)

The bootstrap compiler runs in milliseconds for ordinary programs. The pure-syslib path takes 30 seconds because `syslib.i` is 9000 lines of INTERCAL that must be tokenised, parsed and emitted; the cache mode (see [syslib.md](syslib.md)) brings it back to milliseconds after one warming. By Hoare's standard, native and cache modes pass; pure-syslib does not.

This is not a parodic violation, just an artefact of expressing a syslib in the language itself. Cache mode is Hoare-compliant.

### Efficient code (violated, by indifference)

We have no production users for whom runtime performance matters. Compiled INTERCAL programs are many orders of magnitude slower than equivalent C, because every operator is a runtime call and there is no register allocator. Hoare's principle is violated by indifference, not by intent.

For a language that takes itself seriously this would be unacceptable. For INTERCAL it is irrelevant.

### Readability (violated, on purpose)

`DO ,1 SUB #4 <- #0` is readable in the sense that a careful reader can derive its meaning, but not in the sense Hoare meant, the meaning is not evident on first reading. The Turing Text Model output makes a sequence of constants look like a string only after one knows the encoding. The politeness rule encourages `PLEASE` to appear at distributed positions for compliance reasons rather than for emphasis.

This is the principle INTERCAL violates most enthusiastically. Reading INTERCAL is the reward of having learned INTERCAL; it does not give itself away.

## Why a deliberately bad language is interesting

Hoare's principles are correct for production languages. INTERCAL is not a production language. Its value is exactly that it occupies the design space *opposite* the principles, and by doing so makes them more visible. A reader of INTERCAL learns by contrast what each of simplicity, security, readability buys for the languages that respect it.

This framing, design as parody, is older than INTERCAL but INTERCAL was the first programming language to embrace it explicitly. The wave of esoteric languages that followed (Brainfuck, Befunge, Malbolge, Shakespeare, Whitespace) each picked one of Hoare's principles to violate even more aggressively than INTERCAL did. Brainfuck violates *expressiveness*. Malbolge violates *predictability*. Shakespeare violates *the boundary between code and prose*. None of them is useful for production work; all of them sharpen the reader's sense of what production languages are doing.

## Niklaus Wirth's perspective

Wirth is the closest thing to a counterpoint within the language-design canon. His Pascal (1970), Modula-2 (1978), and Oberon (1987) progression is a study in stripping a language down, each successor has fewer features than its predecessor, and each is designed to compile in one pass. Wirth's principle could be summarised as "a language is finished when there is nothing left to take away".

INTERCAL violates this principle by accumulating idiosyncrasies. Every revision of the spec adds features (COME FROM was added by C-INTERCAL in 1990; Label 666 by CLC-INTERCAL; quantum operators by CLC-INTERCAL). Each addition is in the spirit of the original, more deliberate inconvenience, but the overall trajectory is one of accretion rather than reduction.

This is not failure relative to Wirth; it is genre divergence. Wirth designs production languages that aim for elegance through subtraction. INTERCAL designers aim for parody through accretion. Both can be right because they are answering different questions.

## What INTERCAL teaches that the canon does not

Reading Hoare and Wirth in isolation produces a particular kind of language designer: one who optimises for what compilers do well. INTERCAL adds a complementary lesson: the things compilers can be forced to do badly. The politeness rule teaches that compile-time predicates can be arbitrary properties of the whole program. The Turing Text Model teaches that I/O semantics can be functionally complete and operationally absurd at the same time. `COME FROM` teaches that control flow primitives can be designed to make programs harder, not easier, to read.

A language designer who reads only the canon ends up with one set of answers. A designer who also reads INTERCAL has a wider hypothesis space, including hypotheses they will deliberately reject, which is what hypothesis spaces are for.

## Where INTERCAL stops being parody

Some features of INTERCAL would be reasonable in a production language:

- The four variable namespaces with explicit prefix sigils (`.` `:` `,` `;`) are clearer than the implicit type system of older Fortran or BASIC.
- The cleanly separated 16-bit and 32-bit numeric types avoid C's promotion rules.
- The strict spark/rabbit-ears alternation is a real solution to the precedence-inference problem, it forces the programmer to be explicit, which is sometimes what you want.

These were not necessarily intended seriously, but they could be lifted out of the parody and put into a serious language. Whether anyone will is a separate question.

## Exercises

1. Read Hoare's 1973 paper (linked in [further-reading.md](further-reading.md)). Pick one principle and find an INTERCAL feature that violates it more egregiously than the examples above.
2. Wirth's Oberon-2 has fewer than 30 reserved words and compiles in one pass. INTERCAL has roughly 25 reserved words. Where is the difference in the *programs* the two languages express?
3. Construct a small INTERCAL program that satisfies Hoare's principle of readability, one that an unprepared reader could understand in one minute. How short does it have to be?
4. The deliberate-anti-design genre that INTERCAL launched has dozens of members today. Is there a Hoare principle that no esolang has yet violated?
5. The spark/rabbit-ears alternation rule, transplanted into a serious language, would make expressions verbose but unambiguous. Sketch what a serious language with this rule would look like. Would anybody use it?

## Next reading

- [history-and-context.md](history-and-context.md): INTERCAL's place in the broader history of language design.
- [esolangs-context.md](esolangs-context.md): the genre INTERCAL launched.
- [further-reading.md](further-reading.md): Hoare, Wirth, and the canonical literature on language design.
