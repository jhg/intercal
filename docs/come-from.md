# `COME FROM`: the inverse of `GOTO`

`COME FROM` is INTERCAL's contribution to the mythology of programming-language control flow. Where `GOTO` says "execution continues over there", `COME FROM` says "after that other statement runs, execution resumes here". The two are inverses in a precise sense: a program with a `GOTO` from A to B has the same control flow as a program with a `COME FROM A` next to where B would have been. The crucial difference is that the targeted statement does not know it has a follower.

This chapter is the complete tour: history, semantics, our static-resolution algorithm, the multi-target rejection, and the threading possibilities that other implementations expose.

## Origins

`COME FROM` was not part of the original 1972 INTERCAL specification. It first appeared in print in R. Lawrence Clark's 1973 article *We Don't Know Where to GOTO if We Don't Know Where We've COME FROM*, published in *Datamation*. Clark's article was a satire of the structured programming debate then raging. Edsger Dijkstra had published *Go To Statement Considered Harmful* in 1968, and Clark proposed `COME FROM` as a deliberate provocation.

The proposal was, at the time, a joke. It became serious when Eric Raymond's C-INTERCAL added it to the language in 1990, on the reasonable grounds that any language designed to mock convention should include the most thoroughly mocked control structure in the literature. CLC-INTERCAL adopted it as well. Every modern INTERCAL implementation, including ours, treats it as canonical.

## Semantics

A `COME FROM (N)` statement attaches itself to the labelled statement at label `N`. The program text contains both the `(N) DO ...` statement (the *target*) and the `DO COME FROM (N)` statement (the *follower*). Their textual order does not matter; the relationship is purely topological.

When the program runs, the target statement executes normally. After it finishes, and instead of falling through to the next statement, control transfers to the follower. The follower executes its own body, then falls through to the statement after it.

In flow-graph terms, `COME FROM (N)` modifies the *exit edge* of statement N: it adds a back edge from N's exit to the follower's entry. The original fall-through edge from N to N+1 is removed.

Two consequences worth dwelling on:

1. **The target is unaware**: a programmer reading the target statement learns nothing about the redirection. To understand a label's behaviour, you have to scan the entire program for `COME FROM` statements that mention that label.
2. **The redirection is unconditional**: no probability, no condition. Every execution of the target statement triggers the follower (modulo the follower's own probability and abstain flags).

## Our resolution algorithm

We resolve `COME FROM` statically, at compile time, in the `resolve_come_from` pass, so that the runtime cost is a single unconditional jump appended to the target's code. The algorithm:

1. Walk every statement. If its type is `COME_FROM`, extract the target label from `stmt_cf_target`.
2. Look the target up in `label_to_stmt`. If the label is undefined, fire `ICL129I`. (Note: this check is currently delegated to the codegen; a refactor would move it here.)
3. Look the target up in `come_from_target`. If a previous `COME FROM` already registered for this label, fire `ICL555I MULTIPLE COME FROM TARGETING SAME LABEL`. This is the multi-target rejection, see below.
4. Otherwise, register `come_from_target[target_label] = follower_index`.

Codegen then consults `come_from_target` when emitting each statement's body. If a follower is registered for this statement's label, the codegen appends an unconditional branch (`b _stmt_<follower>_start` on ARM64, `jmp _stmt_<follower>_start` on x86-64) to the body, before the statement's `_end:` marker. The peephole optimiser drops the branch if `_stmt_<follower>_start` immediately follows.

## The multi-target rejection

Two `COME FROM (N)` statements both targeting the same label `N` is, in the original INTERCAL spec, an error: `ICL555I MULTIPLE COME FROM TARGETING SAME LABEL`. CLC-INTERCAL repurposed the construct as a primitive for *threading*: when N executes, both followers get a copy of the execution context, and the program continues with two parallel flows. The spec does not require this, and our implementation does not provide it.

Earlier versions of our compiler had a latent bug here: `resolve_come_from` registered the second follower silently, so the second `COME FROM` won and the first was lost. The check now fires `ICL555I` correctly.

## The compile-time-resolution choice

A more permissive design would resolve `COME FROM` at runtime: maintain a hash table of label → follower at runtime, and look up the follower at the end of each statement. This would let `COME FROM` targets be computed dynamically (CLC-INTERCAL's "computed `COME FROM`"). But it would make the per-statement runtime cost real: every statement would pay a dictionary lookup for a feature it usually does not use.

Our static resolution gives `COME FROM` zero cost on statements that are not targeted, and one branch on statements that are. The trade is: we cannot support computed targets. Our spec compliance is the C-INTERCAL subset, not the CLC-INTERCAL extension.

## What `COME FROM` is good for

In a language without `IF`, `COME FROM` is one of the few ways to express conditional execution that is not abstention-based. The pattern:

    (10) DO whatever_the_main_path_is
         DO RESUME #1                ; or some similar "stop now"
    
    (20) DO COME FROM (10)
         DO whatever_else
         DO GIVE UP

Statement 10 executes, then control jumps to statement 20 instead of falling through to its next statement. This is approximately a `THEN` clause attached after the fact.

More elaborate patterns use `COME FROM` in conjunction with `ABSTAIN` to build dispatch tables, with each entry being a `COME FROM` that is initially abstained and gets reinstated by a controller statement when a particular branch should run. The cost of these patterns is that the program becomes hard to read top-to-bottom; the benefit is that you can express `if-then-else` chains without an `IF`.

## How other languages have borrowed it

`COME FROM` has been adopted, mostly as a joke, by several languages outside INTERCAL:

- The Perl module `Acme::ComeFrom`, which adds the construct to Perl 5 in roughly 50 lines of XS magic. The module is functional and was used at least once in production by accident.
- A 2004 April Fool's RFC (RFC 3514, the "evil bit") references `COME FROM` as part of its parody apparatus.
- Brendan Eich considered (and rejected) `COME FROM` for early JavaScript. The story is apocryphal but plausible given the era.

The construct also appears, unintentionally, in any language that supports aspect-oriented programming, an "after" advice on a method is precisely a `COME FROM` for that method. AspectJ and similar systems make the relationship visible; INTERCAL just makes it a punchline.

## Why no `GOTO`?

INTERCAL has `NEXT` (the labelled jump that pushes a return address) and `RESUME` (the labelled jump that pops a return address). Together they cover the same ground as `GOTO` plus subroutine call/return. The spec deliberately omits a plain unconditional jump because, as the manual puts it, "we want the programmer to think harder about each control transfer."

`COME FROM`, in this scheme, is the inverse of the missing `GOTO` rather than of `NEXT`. The asymmetry is deliberate.

## Exercises

1. Write a six-statement INTERCAL program that uses `COME FROM` to produce two output lines. Trace the control flow on paper.
2. Convert a hypothetical `IF .1 THEN ... ELSE ...` into the INTERCAL idiom using `COME FROM` plus `ABSTAIN`. Count the statements you needed.
3. Two `COME FROM (10)` statements are now an error. Write the test program that exercises the error and confirm it fires `ICL555I`.
4. The static resolution gives zero-cost on untargeted statements and one branch on targeted ones. What would the runtime cost be if we instead resolved dynamically?
5. CLC-INTERCAL's "computed `COME FROM`" allows the target label to be an expression. What problem would arise in our static-resolution approach if we tried to support it?

## Next reading

- [semantic-analysis.md](semantic-analysis.md): the resolution pass in context.
- [code-generation.md](code-generation.md): how the back-edge is emitted.
- [intercal-primer.md](intercal-primer.md): the brief introduction.
- [history-and-context.md](history-and-context.md): Clark's 1973 article in its broader context.
