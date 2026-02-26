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

### Runtime library (native layer)

INTERCAL cannot express everything a program needs. Some operations require direct access to the operating system. The compiler must provide a runtime library in assembly (or generated machine code) that every executable links against. This runtime provides:

- I/O syscalls: READ OUT needs to write to stdout (Roman numerals for scalars, Turing Text Model for arrays). WRITE IN needs to read from stdin and parse spelled-out English digit names.
- Process termination: GIVE UP needs the exit syscall.
- Memory management: dynamic allocation for arrays (dimensioning, redimensioning) and for STASH variable stacks (which grow unbounded).
- Random number source: syslib labels 1900 and 1910 need OS-level randomness (e.g. getrandom syscall, /dev/urandom).

This runtime is platform-specific assembly. Each target platform (macOS arm64, Linux x86_64, etc.) needs its own implementation.

### System library (syslib) strategy

The syslib provides arithmetic at labels 1000-1999. There are two layers:

1. Arithmetic routines (labels 1000-1550): these CAN be written in pure INTERCAL. Addition, subtraction, multiplication and division are all implementable using only mingle, select, and the unary bitwise operators. This is the natural approach -- the compiler includes and compiles syslib.i alongside user code.
2. Random number routines (labels 1900-1910): these CANNOT be pure INTERCAL because they need a source of randomness from the OS. These routines must call into the native runtime library.

The compiler should auto-detect when a program uses NEXT to labels in the 1000-1999 range and include syslib automatically. The syslib for this compiler will be an original implementation, not copied from any existing syslib source.

In summary, the executable contains three parts:
- User code: compiled from the .i source file.
- Syslib: arithmetic in INTERCAL (compiled alongside user code) + random routines bridging to native.
- Runtime: assembly providing syscalls for I/O, exit, memory, and randomness.

## INTERCAL language reference

This section documents the INTERCAL language features the compiler must support. All content is written from understanding of the language semantics, not copied from any source.

### Statement structure

Every statement has these components in order:
1. Optional line label: a number 1-65535 in parentheses, e.g. `(10)`. Must be unique. Labels 1000-1999 are reserved for the system library.
2. Required identifier: `DO`, `PLEASE`, or `PLEASE DO` (all equivalent functionally).
3. Optional negation: `NOT` or `N'T` makes the statement abstained (inactive) at startup.
4. Optional probability: `%` followed by 0-100, the percentage chance of execution. Default is 100.
5. The statement body.

Execution starts at the first statement and ends at `GIVE UP`. Reaching the end without `GIVE UP` causes error E633.

Whitespace is ignored except within keywords. Multiple statements can be on one line or a statement can span multiple lines.

### Politeness rule

At least 1/5 and at most 1/3 of statements must use `PLEASE` or `PLEASE DO`. Fewer than 1/5 is rude (compiler rejects with E079). More than 1/3 is sycophantic (compiler rejects with E099). This compiler enforces this rule.

### Data types

Four variable types, each with a prefix symbol and a number 1-65535:

| Prefix | Name | Type |
|--------|------|------|
| `.` (spot) | onespot | 16-bit unsigned integer (0-65535) |
| `:` (two-spot) | twospot | 32-bit unsigned integer (0-4294967295) |
| `,` (tail) | tail array | array of 16-bit values |
| `;` (hybrid) | hybrid array | array of 32-bit values |

Constants use `#` (mesh) prefix followed by a value, always 16-bit. For 32-bit constants, construct with operators (e.g. mingle two 16-bit values).

Variables are implicitly initialized to zero. Assigning a value larger than 65535 to a onespot variable causes error E275.

### Operators

No operator precedence exists. Expressions must use explicit grouping with `'` (spark) and `"` (rabbit-ears). These must alternate nesting: sparks inside rabbit-ears or vice versa, never same-type nesting.

Binary operators:
- `$` (big money) -- interleave/mingle: takes two 16-bit values, alternates their bits to produce a 32-bit result. Left operand bits go to odd positions (1,3,5...), right operand bits go to even positions (0,2,4...).
- `~` (sqiggle) -- select: examines each bit of the right operand (mask); wherever the mask has a 1, extracts the corresponding bit from the left operand. Extracted bits are packed right-justified (from lowest mask-1 position to highest, placed at result positions 0,1,2...). Result is 16-bit if 16 or fewer bits selected, 32-bit otherwise. Key property: X~X equals (2^popcount(X))-1, so any nonzero value selected from itself is nonzero, while 0~0 is 0.

Unary operators (placed between prefix and number, e.g. `&.1`):
- `&` (ampersand) -- AND of adjacent bits with wrap-around.
- `V` (book, uppercase V) -- OR of adjacent bits with wrap-around.
- `?` (what) -- XOR of adjacent bits with wrap-around.

Unary operator semantics: the operation is equivalent to rotating the value right by 1 bit (LSB wraps to MSB), then performing the two-operand logical operation between the original and the rotated version. For a 16-bit value, result bit N = bit N OP bit (N+1 mod 16). For 32-bit, bit N OP bit (N+1 mod 32).

### Assignment

Uses `<-` (angle-worm): `DO .1 <- #5` assigns value 5 to onespot variable 1.

### Control flow

- `DO (label) NEXT` -- transfers to labeled statement, pushes return address on NEXT stack. Stack limit is 79 entries; reaching 80 causes error E123.
- `DO RESUME expression` -- pops N entries from NEXT stack, returns to the last popped address. `RESUME #1` is a subroutine return. `RESUME #0` causes error E621.
- `DO FORGET expression` -- removes N entries from NEXT stack without transferring control. Forgetting more than exist just empties the stack.
- `DO COME FROM (label)` -- after the labeled statement executes, control transfers here. Only one COME FROM per label (E555 otherwise). Note: COME FROM was not part of the original INTERCAL-72 specification; this compiler adopts it as a standard feature.
- `GIVE UP` -- terminates the program.

There is no IF, WHILE, FOR, or GOTO. Conditional logic is achieved through ABSTAIN/REINSTATE combined with NEXT/RESUME.

### Statement modifiers

- `DO ABSTAIN FROM (label)` -- deactivates a specific statement. `DO ABSTAIN FROM gerund-list` deactivates all statements of that type. Recognized gerunds: CALCULATING, NEXTING, FORGETTING, RESUMING, STASHING, RETRIEVING, IGNORING, REMEMBERING, ABSTAINING, REINSTATING, COMING FROM, READING OUT, WRITING IN.
- `DO REINSTATE (label)` or `DO REINSTATE gerund-list` -- reactivates previously abstained statements.
- `DO IGNORE variable-list` -- makes variables read-only (writes are silently discarded).
- `DO REMEMBER variable-list` -- reverses IGNORE, makes variables writable again.

### Arrays

Dimensioned via assignment with `BY` for multi-dimensional:
- `DO ,1 <- #10` -- 1D tail array of size 10
- `DO ,1 <- #3 BY #4` -- 2D tail array, 3x4

Arrays are 1-indexed. Elements accessed with `SUB`: `,1 SUB #3` or `,1 SUB .1 SUB .2` for multi-dimensional. Redimensioning destroys contents.

### Stash and retrieve

- `DO STASH variable-list` -- pushes copies of variables onto per-variable stacks. Current values remain.
- `DO RETRIEVE variable-list` -- pops most recent saved values. Error E436 if nothing stashed. Works LIFO.

Used for preserving state across subroutine calls (no local scope exists) and before redimensioning arrays.

### I/O

Numeric I/O:
- `DO WRITE IN variable-list` -- reads input. User must type digit names in English (ONE TWO THREE for 123).
- `DO READ OUT variable-list` -- writes output in Roman numeral notation. Overbar notation for values 4000+.

Character I/O (Turing Text Model):
- Uses arrays (READ OUT an array for output, WRITE IN an array for input).
- An imaginary tape loop of 256 characters, with a tape head starting at position 0.
- For output, the tape head is viewed from the reverse side, so characters appear in reverse direction and each character's bits are reversed (bit 0 swaps with bit 7, etc.).
- Algorithm to compute array values for a desired output string:
  1. Start with previous_position = 0.
  2. For each character: take its ASCII code, reverse all 8 bits to get the internal_position.
  3. Array value = (previous_position - internal_position) mod 256.
  4. Set previous_position = internal_position for the next character.
- For input, the reverse: each array element is the distance the tape moves, and the character at the new position (after bit-reversal) is the input character.
- Input and output use separate tape heads, both starting at position 0. They do not share state.
- No newline is appended automatically after READ OUT. Programs must encode it as an additional array element if needed.

### Character set names

INTERCAL assigns names to symbols: spot (`.`), two-spot (`:`), tail (`,`), hybrid (`;`), mesh (`#`), spark (`'`), rabbit-ears (`"`), wow (`!`), what (`?`), double-oh-seven (`%`), worm (`-`), angle (`<`), wax (`(`), wane (`)`), splat (`*`), ampersand (`&`), book (`V`), big money (`$`), sqiggle (`~`), intersection (`+`).

### System library

Since INTERCAL only has bitwise operators, arithmetic is provided by the system library (syslib.i) via NEXT to labels 1000-1999. This compiler should auto-include syslib when it detects NEXT to labels in this range.

16-bit arithmetic (spot variables):
- Label 1000: .3 = .1 + .2 (error on overflow)
- Label 1009: .3 = .1 + .2, .4 = #1 if no overflow, #2 if overflow
- Label 1010: .3 = .1 - .2 (unsigned, wraps on underflow, no error)
- Label 1020: .1 = .1 + 1 (in-place increment, wraps, no error)
- Label 1030: .3 = .1 * .2 (error on overflow)
- Label 1039: .3 = .1 * .2, .4 = #1 if no overflow, #2 if overflow
- Label 1040: .3 = .1 / .2 (integer division; .3 = 0 if .2 = 0)
- Label 1050: .2 = :1 / .1 (32-bit / 16-bit -> 16-bit; error on overflow; .2 = 0 if .1 = 0)

32-bit arithmetic (two-spot variables):
- Label 1500: :3 = :1 + :2 (error on overflow)
- Label 1509: :3 = :1 + :2; overflow flag in :4 (#1 = no overflow, #2 = overflow)
- Label 1510: :3 = :1 - :2 (unsigned, wraps, no error)
- Label 1520: :1 = .1 $ .2 (mingle two 16-bit into 32-bit)
- Label 1530: :1 = .1 * .2 (16-bit * 16-bit -> 32-bit, no overflow possible)
- Label 1540: :3 = :1 * :2 (error on overflow)
- Label 1549: :3 = :1 * :2; overflow flag in :4 (#1 = no overflow, #2 = overflow)
- Label 1550: :3 = :1 / :2 (integer division; :3 = 0 if :2 = 0)

Random:
- Label 1900: .1 = uniform random 0-65535
- Label 1910: .2 = random in range 0-.1 with stdev approximately .1/12

Internal labels: 1525 (shift .3 left by 8 bits, internal use only) and 1999 (overflow error exit, triggers runtime error). These are not meant to be called by user code.

All syslib routines use STASH/RETRIEVE internally for their temporaries, so they do not corrupt variables beyond the documented inputs/outputs.

### Error codes

The compiler must recognize and produce errors in the format ICLnnnI (I = error, W = warning). Errors are fatal; warnings are not. Key errors:

Compile-time errors:
- E079: fewer than 1/5 of statements use PLEASE (insufficiently polite)
- E099: more than 1/3 of statements use PLEASE (overly polite)
- E182: duplicate line label
- E197: label outside 1-65535
- E774: random compiler bug (deliberate, can be suppressed)

Runtime errors (most INTERCAL errors are runtime, because unrecognized statements are not flagged at compile time -- they might be abstained):
- E000: undecodable statement reached during execution
- E017: syntax error in expression reached during execution
- E123: NEXT stack overflow (80th NEXT attempted; limit is 79)
- E129: NEXT to non-existent label
- E139: ABSTAIN/REINSTATE references non-existent label
- E200: unidentified variable reference
- E240: array dimension of zero
- E241: invalid array subscript (wrong number of subscripts or out of bounds)
- E275: 32-bit value assigned to 16-bit variable
- E436: RETRIEVE without prior STASH
- E533: operation produced a value exceeding 32 bits (WRITE IN or mingle)
- E555: multiple COME FROM targeting same label
- E562: insufficient input data (end of input during WRITE IN)
- E579: invalid input format (unrecognized digit name during WRITE IN)
- E621: RESUME with value 0
- E632: program terminated via RESUME instead of GIVE UP (NEXT stack exhausted)
- E633: execution fell off end without GIVE UP

### Extended features (lower priority)

These features are not part of standard INTERCAL but may be considered for future versions of this compiler:

- Computed COME FROM: `DO COME FROM expression` where target is evaluated dynamically.
- NEXT FROM: like COME FROM but saves return address on NEXT stack.
- Threading via COME FROM: multiple COME FROM targeting the same label forks execution.
- TriINTERCAL: base-3 variant with ternary logic operators (.3i to .7i files).
- Backtracking: MAYBE qualifier creates choice points for Prolog-like backtracking.
- Wimpmode: allows normal decimal I/O instead of spelled-out digits and Roman numerals.

## Best practices for INTERCAL development

These guidelines apply to writing the compiler itself in INTERCAL and to writing any INTERCAL test programs.

### Politeness management

- Maintain PLEASE usage between 1/5 and 1/3 of statements (inclusive). A practical ratio is roughly 1 in 4 statements.
- Distribute PLEASE statements evenly throughout the program rather than clustering them.
- When adding or removing statements, recount politeness to stay within bounds.
- Fewer than 1/5 triggers E079 ("PROGRAMMER IS INSUFFICIENTLY POLITE"). More than 1/3 triggers E099 ("PROGRAMMER IS OVERLY POLITE").

### Variable conventions

- Variables .1, .2, .3, .4 and :1, :2, :3, :4 are the syslib interface. Always STASH them before calling syslib routines if their values matter, and RETRIEVE after return.
- Use higher-numbered variables (.10+, :10+) for program-specific data to avoid conflicts.
- Keep array numbering logically separate from scalar numbering for readability (they are distinct namespaces, but using ,1 and .1 for unrelated purposes is confusing).

### NEXT stack discipline

- The stack holds 79 entries. The 80th causes E123 ("PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON").
- Always FORGET #1 after a NEXT that does not need to return (unconditional jump), to prevent stack buildup.
- In NEXT-based loops, place FORGET #1 at the top of each iteration to discard the return address that was just pushed.
- Prefer RESUME #1 for clean subroutine returns.
- RESUME #0 is always an error (E621). Guard against variables that might be zero reaching a RESUME.

### STASH/RETRIEVE discipline

- STASH before calling syslib routines: the caller is responsible for saving any variables that the routine uses as input/output (.1-.4, :1-:4).
- RETRIEVE immediately after the call returns.
- Never STASH inside a loop without a corresponding RETRIEVE -- stash stacks grow unbounded.
- Attempting to RETRIEVE a variable that was never STASHed causes E436.

### Code organization

- Label ranges: use 1-999 for program labels, organized by module (e.g. 100-199, 200-299). Never use 1000-1999 (syslib reserved).
- Place GIVE UP at the logical end of the main flow. Missing it causes E633.
- Group COME FROM statements near the code they transfer to.
- Use abstained statements (with NOT/N'T) as the closest thing to comments. A statement like `DON'T READ OUT .99` is effectively a comment that documents intent without executing.
- INTERCAL has no real comment syntax. Any unrecognized text is silently ignored, but if you accidentally write valid INTERCAL it will compile and execute.

### Essential idioms

Zero test -- check if a value is zero or nonzero:
- `.1 ~ .1` packs all set bits rightward. If .1 is zero, result is 0. If nonzero, result is nonzero.
- `'.1~.1'~#1` extracts the lowest bit: gives 0 if .1 was zero, 1 if nonzero.

Converting 0/1 to 1/2 (needed for computed RESUME):
- `"?'.1$#1'"~#3` converts: 0 becomes 1, 1 becomes 2. This works by mingling with #1, applying unary XOR on the adjacent bits, then selecting the lowest two result bits.
- `"?'.1$#2'"~#3` reverses: 0 becomes 2, 1 becomes 1.

Two-way conditional branch (the fundamental IF equivalent):
1. Compute a variable to hold 1 or 2 (using the conversion above).
2. Set up two NEXT statements to push two return addresses.
3. Execute RESUME with the 1-or-2 variable. RESUME #1 goes to the more recent return point. RESUME #2 pops two and goes to the older one.
- This is the standard four-statement pattern used throughout syslib.

Bitwise logic between two separate values:
- INTERCAL's unary operators work on adjacent bits within one value, not between two values.
- To AND/OR/XOR two 16-bit values A and B: mingle them (A$B) to interleave their bits into adjacent pairs, apply the unary operator, then select even-position bits from the result to extract the answer.
- The even-position mask for a 32-bit result is `'#0$#65535'` which equals 0x55555555 (1431655765). Selecting with this mask extracts the 16 bits at even positions and packs them into a 16-bit result.

Equality test:
- Subtract A from B via syslib 1010. Test the result for zero using the zero-test idiom.

16-bit to 32-bit conversion:
- Assign directly: `DO :1 <- .1` (zero-pads upper 16 bits).

32-bit to 16-bit extraction:
- Lower 16 bits: `DO .1 <- :1 ~ #65535`
- Upper 16 bits: `DO .1 <- :1 ~ '#65535$#0'`
- Direct assignment `DO .1 <- :1` only works if the value fits in 16 bits, otherwise E275.

### Loop patterns

COME FROM loop:
- Place a label on the statement at the top of the loop body.
- Place a COME FROM referencing that label after the loop body.
- Each time the labeled statement executes, control transfers to the COME FROM instead of the next line.
- To break: ABSTAIN FROM the COME FROM statement (by its label), then execution proceeds normally past the labeled statement.

NEXT-based loop:
- The loop body ends with a NEXT back to the top.
- FORGET #1 at the top of each iteration prevents stack overflow.
- To exit: skip the NEXT (via ABSTAIN or a computed branch).

Counted loop (iterate N times):
1. Set counter variable to N.
2. At each iteration: subtract 1 (syslib 1010), test for zero, convert to 1/2, use computed RESUME to continue or exit.

### I/O practices

- For text output, precompute all Turing tape offset values into an array, then READ OUT the array in one statement.
- The algorithm for output values: reverse the 8 bits of each target ASCII code, compute (previous_internal_position - reversed_code) mod 256.
- For debugging, READ OUT of scalar variables gives Roman numeral output, which is sufficient to verify intermediate values.

### Debugging

- Use READ OUT to print intermediate values at key points.
- Temporarily ABSTAIN FROM sections to isolate problems.
- Error messages report the next statement that would execute, not the one that failed -- look one statement before the reported position.
- When E123 occurs, look for NEXT without corresponding FORGET or RESUME in loops.
- When E275 occurs, an expression produced a value larger than 65535 being assigned to a 16-bit variable -- check operator results.

### Portability

- Use only standard INTERCAL features; avoid extensions listed in "Extended features" above.
- Stick to base-2 INTERCAL (.i files) unless multi-base support is implemented.
- Do not depend on random compiler bug behavior (E774).
- Use only standard syslib labels; do not assume supplementary libraries are available.
- Always respect the politeness rule -- this compiler enforces it.

### Common mistakes to avoid

- Forgetting GIVE UP at the end (E633).
- Using labels 1000-1999 (conflicts with syslib, E182).
- RESUME with a variable that could be 0 (E621).
- Calling syslib without first STASHing variables you need (.1-.4, :1-:4).
- Nesting sparks inside sparks or rabbit-ears inside rabbit-ears (must alternate).
- Writing what looks like a comment but is valid INTERCAL (it will execute).
- Assigning 32-bit expression results to 16-bit variables without checking range (E275).
- STASH in a loop without RETRIEVE (unbounded stack growth).
- Deep NEXT chains without FORGET (E123 after 79 levels).

## Viability

La investigación revela una situación clara con implicaciones importantes para el proyecto.

INTERCAL estandar NO tiene:

- Lectura/escritura de archivos (solo stdin/stdout)
- Acceso a argumentos de linea de comandos (argc/argv)
- FFI ni llamadas a funciones nativas
- Llamadas al sistema operativo
- Carga de librerias dinamicas

INTERCAL estandar SI tiene:

- Turing-completeness (demostrado formalmente)
- I/O binario via Turing Text Model (arrays): puede leer/escribir TODOS los 256 valores de byte (0x00-0xFF) via stdin/stdout
- 65535 variables de cada tipo, 65535 labels (suficiente para un compilador)
- Programas complejos existentes: un interprete Unlambda (~857 lineas), un interprete Befunge-93 (~713 lineas), una libreria de punto flotante (~2000 lineas)

El camino viable: compilador como filtro stdin/stdout

El compilador puede funcionar asi:
./compiler < source.i > output
chmod +x output

- Lee el codigo fuente byte a byte desde stdin via Turing Text Model
- Escribe el binario ejecutable byte a byte a stdout via Turing Text Model
- El shell maneja la redireccion de archivos, no INTERCAL

Esto es suficiente para un compilador self-compiled. Muchos compiladores historicos funcionaban asi.

El problema critico: necesitamos una libreria nativa para las extensiones

El compilador INTERCAL puro puede compilarse a si mismo usando stdin/stdout.

Pero los programas compilados por el necesitan un runtime nativo (para I/O, syscalls, exit, etc.). El compilador necesita:

1. Poder generar bytes de codigo maquina (posible via Turing Text Model)
2. Tener el runtime en ensamblador como datos embebidos o como archivo separado

Sobre enlazar con librerias estaticas en ensamblador

INTERCAL estandar NO puede enlazar con librerias externas. Sin embargo:
- C-INTERCAL tiene un sistema de "external calls" (-e) que permite enlazar archivos C
- CLC-INTERCAL tiene syscalls via label (666)
- Nuestro compilador NO necesita estas extensiones para compilarse

La razon: nuestro compilador no necesita enlazar con nada durante su propia ejecucion. El genera el ejecutable de salida como un stream de bytes (que incluye el runtime embebido). El runtime solo se
necesita dentro del ejecutable generado, no en el compilador mismo.

Estructura propuesta

compilador (ejecutable INTERCAL):
  - lee .i desde stdin
  - escribe binario nativo a stdout
  - internamente contiene:
    - parser del lenguaje INTERCAL
    - generador de codigo maquina
    - datos del runtime (bytes de ensamblador pre-ensamblados)
    - datos del syslib (compilado desde INTERCAL puro)

Conclusion de viabilidad

Es posible. El compilador self-compiled en INTERCAL puro es teoricamente viable porque:
1. INTERCAL es Turing-complete
2. Puede leer/escribir bytes arbitrarios via stdin/stdout
3. Hay precedente de programas INTERCAL complejos (interpretes, libreria FP)
4. El limite de 65535 labels y variables es suficiente
5. No necesita file I/O ni argv (usa redireccion del shell)

Las limitaciones practicas son: sera extremadamente lento, muy dificil de depurar, y el codigo sera muy extenso. Pero no es imposible.

Sería interesante revisar las opciones de C-INTERCAL de external calls y CLC-INTERCAL de syscalls con label 666, a priori parece la más idiomatica y que se acercaría al estandar aunque sea algo propio de este compilador y CLC-INTERCAL solo. La primera versión deberia usar las pipes por simplicidad y asegurar compatibilidad con cualquier compilador de intercal actual, y luego podriamos explorar el extenderlo con alguna de estas soluciones para evitar que tanto el compilador como los programas creados se vean demasiado limitados sin posibilidad de extension.
