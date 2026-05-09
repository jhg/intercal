#!/bin/zsh
# Static check for zsh quirks that have bitten this codebase.
# Currently catches:
#   1. Bare 'local NAME' immediately followed by 'for NAME in ...'
#      or 'for ((NAME=...))' — leaks 'NAME=value' to stdout.
#   2. ${var//pat/$'X'} — $'X' inside parameter-expansion replacement
#      is not interpreted as a C-escape, leaving literal "$'X'" in
#      the result.
#
# Usage:
#   tools/lint_zsh_quirks.sh path1 [path2 ...]
#   find src tools tests -name '*.sh' | xargs tools/lint_zsh_quirks.sh
#
# Exit code: 0 if no findings, 1 if any.
set -euo pipefail

ERRORS=0

for f in "$@"; do
  [[ ! -f "$f" ]] && continue

  # Pattern 1: bare 'local NAME' followed by 'for NAME in/((NAME='.
  python3 - "$f" <<'PY'
import re, sys
path = sys.argv[1]
lines = open(path).read().splitlines()
for i, line in enumerate(lines):
    m = re.match(r'^(\s+local\s+)([A-Za-z_][A-Za-z0-9_]*)(\s*)$', line)
    if not m: continue
    var = m.group(2)
    j = i + 1
    while j < len(lines) and not lines[j].strip():
        j += 1
    if j >= len(lines): continue
    nxt = lines[j]
    if (re.search(rf'\bfor\s*\(\(\s*{var}\s*=', nxt)
        or re.search(rf'\bfor\s+{var}\s+in\b', nxt)):
        print(f'{path}:{i+1}: error: bare "local {var}" before "for {var}" leaks to stdout. Initialise on declaration line: local {var}="" or local {var}=0')
        sys.exit(1)
PY
  rc=$?
  (( rc != 0 )) && ERRORS=$((ERRORS + 1))

  # Pattern 2: ${var//.../$'something'} on a non-comment line.
  python3 - "$f" <<'PY'
import re, sys
path = sys.argv[1]
for i, line in enumerate(open(path).read().splitlines()):
    stripped = line.lstrip()
    if stripped.startswith('#'):
        continue
    # Narrow rule: pattern starts with backslash-escape AND
    # replacement is $'\\X' where X is a single escape char. The
    # known-bad case from the LSP bug. Patterns with literal text
    # before the slash (e.g., '${src//DO /$'\\n'DO }') work
    # empirically and are NOT flagged.
    if re.search(r"\$\{[^}]*//\\\\[a-z][a-zA-Z]?/\$\'\\\\[a-z][a-zA-Z]?\'[^}]*\}", line):
        print(f'{path}:{i+1}: error: $\'\\\\X\' inside parameter-expansion replacement against \\\\X pattern: known to NOT interpret the escape. Hoist newline/cr to a local variable first.')
        sys.exit(1)
PY
  rc=$?
  (( rc != 0 )) && ERRORS=$((ERRORS + 1))
done

if (( ERRORS == 0 )); then
  echo "lint_zsh_quirks: no findings in ${#@} file(s)"
  exit 0
fi
exit 1
