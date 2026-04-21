# Lexing and parsing

The compiler's front-end is short. It lives entirely in `src/bootstrap/intercalc.sh`, split across `tokenize()` (lines 68–261), `parse_number()` (lines 399–414), and `parse_expr()` (lines 415–602). This chapter walks through both phases in the same order the compiler runs them.

## The lexer, viewed from a distance

At the point `tokenize()` starts, `SOURCE` is a single string with every newline and tab collapsed to a space and everything uppercased. The lexer's whole job is to split that string into a list of statements, each with its modifiers and body already pulled out.

One statement, expressed as the tuple that will live in the parallel `stmt_*` arrays:

    stmt_label[i]       — e.g. "(1000)" or ""
    stmt_polite[i]      — 1 if PLEASE was present, 0 otherwise
    stmt_negated[i]     — 1 if NOT / N'T / DON'T was present, 0 otherwise
    stmt_prob[i]        — 100 by default, otherwise the %N value
    stmt_type[i]        — ASSIGN, NEXT, RESUME, FORGET, ABSTAIN, REINSTATE,
                          IGNORE, REMEMBER, STASH, RETRIEVE, READ_OUT, WRITE_IN,
                          COME_FROM, GIVE_UP, or UNKNOWN
    stmt_body[i]        — the raw body text after modifiers have been consumed

The lexer does not tokenize the body's expressions. That is deferred to codegen time, when `codegen_<type>` calls `parse_expr()` on the body. Deferring is cheap and makes the lexer simpler: the statement-level lexer only needs to know where one statement ends and the next begins.

## How statement boundaries are detected

A new statement begins at any of: `DO`, `PLEASE`, `PLEASE DO`, `DON'T`, `PLEASE DON'T`. Looking for those verbs is what the main scanning loop in `tokenize()` does.

Each iteration:

1. Skip whitespace.
2. Try to match an optional label `(N)`. If present, consume it and save for the next statement.
3. Try to match one of the verb tokens above. If none, abort — a program whose first non-whitespace content isn't a verb is malformed.
4. Record whether PLEASE was seen (`polite=1`) and whether a negation was seen (`negated=1`). `DON'T` counts as `DO` + negation.
5. Optionally match `%N` for probability.
6. Look at the next keyword to classify the statement type:
   - `.` / `:` / `,` / `;` prefix → `ASSIGN`
   - `(` followed by a number and `)` followed by `NEXT` → `NEXT`
   - `RESUME` / `FORGET` / `ABSTAIN` / `REINSTATE` / `IGNORE` / `REMEMBER` / `STASH` / `RETRIEVE` / `READ OUT` / `WRITE IN` / `COME FROM` / `GIVE UP` — each maps to the obvious type.
   - Anything else → `UNKNOWN`.
7. Scan forward up to the next verb token or end-of-string. Everything in between is the body.

Point 7 is the interesting one. Statement bodies can contain sparks and rabbit-ears, and those contain tokens that look like statements. The scanner doesn't try to parse them; it just counts balanced sparks/rabbit-ears to know when a body candidate ends. This is sloppy but works because INTERCAL's statement verbs (`DO`, `PLEASE`, etc.) never appear inside an expression.

## The `DON'T NOTE ...` trap and how the lexer handles it

An earlier iteration of the lexer produced `DO` + `N'T` as two separate tokens. This failed on constructions like `DON'T NOTE foo bar`, because after `DO` + `N'T`, the scanner did not recognise `NOTE foo bar` as a new statement and attached it to the previous statement's body. The fix was to treat `DON'T` as a single token. There is no `D` + `ON'T` decomposition anywhere in the tokenizer.

This is the reason `DON'T NOTE` is the idiomatic "comment": it parses as a standalone negated statement of type `UNKNOWN`, which the codegen maps to nothing and which would never execute even if reinstated (attempting to execute `UNKNOWN` fires ICL000I, which is fine because it was never reinstated in the first place).

## The expression parser

Expressions are parsed only when codegen asks for them, by `parse_expr()`. The parser is a recursive descent over the body text, consuming it left-to-right.

The grammar of an expression in INTERCAL is, in informal form:

    expr      ::= primary op_tail*
    op_tail   ::= binop primary
    binop     ::= '$' | '~'
    primary   ::= const | variable | grouped | array_ref
    const     ::= '#' NUMBER
    variable  ::= unary? prefix NUMBER
    unary     ::= '&' | 'V' | '?'
    prefix    ::= '.' | ':' | ',' | ';'
    grouped   ::= "'" expr "'"   |   '"' expr '"'
    array_ref ::= variable 'SUB' primary (primary)*

Plus the rule that nested grouping must alternate spark ↔ rabbit-ears. Our parser does not enforce that rule syntactically; the runtime enforces it only indirectly through the way the tree walks happen. In practice, badly nested sparks produce ICL017I at runtime. That is a latent issue listed in our TODO.

### The expression tree

Expressions are stored as a tree of nodes in parallel arrays:

    expr_type[i]      NODE_CONST, NODE_VAR, NODE_MINGLE, NODE_SELECT,
                      NODE_UNARY_AND, NODE_UNARY_OR, NODE_UNARY_XOR,
                      NODE_ARRAY_REF
    expr_val[i]       constant value, or the variable number
    expr_left[i]      left child (for binary ops)
    expr_right[i]     right child (for binary ops)
    expr_child[i]     single child (for unary ops)
    expr_width[i]     16 or 32 — the width hint used during codegen

Building a new node is a matter of `(( expr_next_id++ ))`, then writing into slot `expr_next_id - 1`. The parser returns the slot index of the root of the sub-expression it just parsed. This style (parallel arrays instead of heap-allocated structs) is a concession to zsh: it is much faster than associative arrays, and the parallel-array pattern carries over directly to the INTERCAL version of the parser in `stage3.i`.

### Why defer expression parsing

Parsing expressions during codegen, not during lexing, has one clear benefit: it keeps the statement-level representation tiny and makes it easy to reason about the statement list as a whole (count politeness, build the label map, resolve COME FROM). When we start generating code for a statement, we already know the statement's type — and only then does it matter how its body is structured.

The cost is that a program with syntactically invalid expressions will compile fine until we try to codegen the offending statement. Since we codegen every statement in order, that delay is invisible in practice.

## Edge cases worth knowing

- Whitespace inside tokens: `DON'T` is one token; `D ON'T` is not valid. The tokenizer matches `DON'T` as a literal keyword after uppercasing, so interior spaces break it.
- Numbers: `#12345` is a decimal literal. The lexer consumes digits greedily after `#`. A constant larger than 65535 is stored anyway; the overflow check happens at codegen/runtime time.
- Array subscripts: `,1 SUB #3` parses as an array reference with one subscript. `,1 SUB .1 SUB .2` parses as a reference with two subscripts, not as nested subscripting. The parser collects subscripts until it sees something that isn't a primary.
- `SUB` is a keyword, not a normal identifier. It is detected specifically during primary parsing.
- Gerund lists (`ABSTAIN FROM NEXTING + CALCULATING`): the parser reads the body as a sequence of gerund names joined by `+`. Each name maps to one of the statement types.

## The INTERCAL-level parser (stage3.i)

The pure-INTERCAL compiler in `src/compiler/stage3.i` will eventually duplicate this logic inside the INTERCAL language itself. Today it only reads the source and emits a few diagnostic bytes. Once it grows, it will use the same parallel-array layout (`,11` for statement labels, `,12` for polite flags, etc.) for the same reason zsh does: constant-time indexing and no heap allocation.

See [self-hosting.md](self-hosting.md) for the stage3 roadmap and [code-generation.md](code-generation.md) for how the tree built here is consumed.
