# Appendix: INTERCAL grammar

This appendix gives a formal grammar for the INTERCAL subset that the compiler accepts. The notation is EBNF, with two deliberate non-strictnesses that track what our parser actually does:

- Alternation uses `|`.
- Optional items are in `[ ]`.
- Repetition (zero or more) uses `{ }`.
- Terminal keywords are in capital letters exactly as they appear in source.
- Literal punctuation is in quotes.
- Whitespace between tokens is implicit and consumed by the lexer.

The grammar is *permissive* in the spirit of INTERCAL: expressions that mix grouping characters in non-alternating ways (`'a + 'b' + c'`) parse, but evaluating them fires a runtime error. The compiler does not statically reject ill-grouped expressions today. Where the grammar is looser than the language specification, a note calls it out.

## Top level

    program         ::= statement { statement }
    statement       ::= [ label ] verb [ negation ] [ probability ] body
    label           ::= "(" number ")"
    verb            ::= "DO" | "PLEASE" | "PLEASE" "DO" | "DON'T" | "PLEASE" "DON'T"
    negation        ::= "NOT" | "N'T"
    probability     ::= "%" number

Note that `DON'T` includes the negation; a `DON'T` verb never carries an additional `NOT` or `N'T`.

The `label` attaches to the statement and is unique across the whole program (duplicates fire ICL182I at compile time).

## Statement bodies

    body            ::= assignment
                      | next_stmt
                      | resume_stmt
                      | forget_stmt
                      | abstain_stmt
                      | reinstate_stmt
                      | ignore_stmt
                      | remember_stmt
                      | stash_stmt
                      | retrieve_stmt
                      | read_out_stmt
                      | write_in_stmt
                      | come_from_stmt
                      | give_up_stmt
                      | unknown

    assignment      ::= lvalue "<-" expr
    lvalue          ::= variable | array_elem
    array_elem      ::= array_ref "SUB" primary { primary }

    next_stmt       ::= "(" number ")" "NEXT"
    resume_stmt     ::= "RESUME" expr
    forget_stmt     ::= "FORGET" expr
    come_from_stmt  ::= "COME" "FROM" "(" number ")"
    give_up_stmt    ::= "GIVE" "UP"

    abstain_stmt    ::= "ABSTAIN" "FROM" ( "(" number ")" | gerund_list )
    reinstate_stmt  ::= "REINSTATE" ( "(" number ")" | gerund_list )
    ignore_stmt     ::= "IGNORE" variable_list
    remember_stmt   ::= "REMEMBER" variable_list
    stash_stmt      ::= "STASH" variable_list
    retrieve_stmt   ::= "RETRIEVE" variable_list

    read_out_stmt   ::= "READ" "OUT" variable_list
    write_in_stmt   ::= "WRITE" "IN" variable_list

    unknown         ::= any_token_sequence

`unknown` is what the lexer assigns to any body that does not match one of the other productions. Executing an unknown statement at runtime fires ICL000I; an unknown statement that starts negated (`DON'T`) is the idiomatic comment syntax in INTERCAL.

## Variables

    variable        ::= spot | twospot | tail_array | hybrid_array
    spot            ::= "." number
    twospot         ::= ":" number
    tail_array      ::= "," number
    hybrid_array    ::= ";" number
    array_ref       ::= tail_array | hybrid_array
    variable_list   ::= variable { variable }

Variable numbers are in the range 1–65535. The namespaces for spot, twospot, tail, and hybrid are independent: `.1`, `:1`, `,1`, `;1` are four unrelated variables.

## Expressions

    expr            ::= primary { binary_op primary }
    binary_op       ::= "$" | "~"
    primary         ::= const
                      | variable
                      | unary_var
                      | grouped
                      | array_elem_ref
    const           ::= "#" number
    unary_var       ::= unary_op ( variable | const )
    unary_op        ::= "&" | "V" | "?"
    grouped         ::= "'" expr "'" | "\"" expr "\""
    array_elem_ref  ::= array_ref "SUB" primary { primary }

There is no operator precedence. Two `binary_op`s in a row read left-to-right: `a $ b ~ c` means `(a $ b) ~ c`. To force right-associated evaluation, use grouping: `a $ 'b ~ c'`.

The language specification requires grouping to alternate between sparks (`'`) and rabbit-ears (`"`): a spark may enclose either a grouped rabbit-ears expression or no grouping at all, but not another spark directly. Our parser does not enforce the alternation. Non-alternating grouping parses successfully; an attempt to evaluate an expression with ambiguous boundaries fires ICL017I at runtime.

## Gerunds

    gerund_list     ::= gerund { "+" gerund }
    gerund          ::= "CALCULATING"
                      | "NEXTING"
                      | "FORGETTING"
                      | "RESUMING"
                      | "STASHING"
                      | "RETRIEVING"
                      | "IGNORING"
                      | "REMEMBERING"
                      | "ABSTAINING"
                      | "REINSTATING"
                      | "COMING" "FROM"
                      | "READING" "OUT"
                      | "WRITING" "IN"

Gerunds are statement-type names used by `ABSTAIN FROM` and `REINSTATE` to operate on whole categories of statements. The mapping to statement types is one-to-one and is resolved at compile time: the codegen walks the statement list once per gerund in the list and emits one flag-store per matching statement.

## Numbers

    number          ::= digit { digit }
    digit           ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"

All numeric literals in source are decimal. There is no hexadecimal or octal syntax. Numbers larger than 65535 are technically valid in the grammar but cause a runtime error (ICL275I) if they flow into a 16-bit slot.

## Whitespace and case

The lexer folds all whitespace (spaces, tabs, newlines) to single spaces, and uppercases every letter. This means the grammar above is case-insensitive in practice: `do .1 <- #5` and `DO .1 <- #5` are identical, as are `please` and `PLEASE`. Keywords in the grammar are written in uppercase because that is the lexer's canonical form.

Internal whitespace in a multi-word keyword is required. `READ OUT` is two tokens separated by at least one space; `READOUT` is not valid.

## What the grammar leaves out

The language specification contains several features we do not implement and that this grammar accordingly omits:

- Unconditional `WRITE IN` / `READ OUT` for non-listed targets is spec-valid in corner cases we have not tested.
- Computed labels and `NEXT FROM` (a CLC-INTERCAL extension) are outside scope.
- MAYBE and the other backtracking extensions are outside scope.
- TriINTERCAL (base 3–7) is outside scope. The file extensions `.3i` through `.7i` are reserved but not consumed.
- Wimpmode (decimal I/O) is outside scope.

The omissions are deliberate. The grammar describes what the compiler accepts today, not what INTERCAL-72 or any downstream dialect defines.

## Differences from the parser

The following are cases where the parser is looser than the grammar above suggests:

- The `unknown` production absorbs any sequence of tokens after the verb. The parser's statement-type classification is greedy: it matches the longest prefix that looks like a known type, and otherwise classifies as `UNKNOWN`.
- `gerund_list` is parsed by a dedicated routine that is tolerant of irregular whitespace around the `+` separator.
- The `variable_list` production is shared by ten statements. The parser implementation is one function (`parse_var_list`) called from each codegen routine.

These are implementation details; the grammar above describes the intended syntax.
