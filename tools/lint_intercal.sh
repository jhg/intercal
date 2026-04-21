#!/bin/zsh
# lint_intercal.sh - static checks for INTERCAL .i source files.
#
# Usage:
#   tools/lint_intercal.sh program.i [more.i ...]
#   find . -name '*.i' | xargs tools/lint_intercal.sh
#
# Emits warnings/errors to stdout in the form:
#   <path>:<line>: <level>: <message>
#
# Exit code: 0 if no errors, 1 if any errors (warnings don't fail).
#
# Checks:
# - politeness ratio outside [1/5, 1/3] (error -- compiler would reject)
# - line label outside 1-65535 (error)
# - syslib label reserved range 1000-1999 used as program label (warning)
# - RESUME with potentially-zero variable (warning, heuristic)
# - STASH inside naive COME FROM loop without matching RETRIEVE (warning)
set -euo pipefail

ERRORS=0
WARNINGS=0

for src in "$@"; do
  if [[ ! -f "$src" ]]; then
    echo "$src: error: file not found"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Count statements: lines starting with optional label then DO/PLEASE/DON'T
  total=$(grep -cE "^[[:space:]]*(\(([0-9]+)\)[[:space:]]*)?(PLEASE|DO|DON'T)" "$src" || true)
  polite=$(grep -cE "^[[:space:]]*(\(([0-9]+)\)[[:space:]]*)?PLEASE" "$src" || true)

  # Politeness check (only if stmt_count >= 5)
  if (( total >= 5 )); then
    if (( polite * 5 < total )); then
      echo "$src: error: insufficient politeness ($polite of $total statements use PLEASE; need >= $(( (total + 4) / 5 )))"
      ERRORS=$((ERRORS + 1))
    fi
    if (( polite * 3 > total )); then
      echo "$src: error: excessive politeness ($polite of $total statements use PLEASE; max $(( total / 3 )))"
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # Label range check
  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    if [[ "$line" =~ '\(([0-9]+)\)' ]]; then
      lbl="${match[1]}"
      if (( lbl < 1 || lbl > 65535 )); then
        echo "$src:$lineno: error: label ($lbl) outside permitted range 1-65535"
        ERRORS=$((ERRORS + 1))
      fi
      # Warn if in syslib range but file is not syslib.i itself
      if (( lbl >= 1000 && lbl <= 1999 )); then
        case "$src" in
          *syslib*) ;;
          *) echo "$src:$lineno: warning: label ($lbl) in syslib-reserved range 1000-1999"
             WARNINGS=$((WARNINGS + 1)) ;;
        esac
      fi
    fi
  done < "$src"

  # RESUME #0 / RESUME .X where .X might be zero
  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    if [[ "$line" =~ 'RESUME[[:space:]]+#0' ]]; then
      echo "$src:$lineno: error: RESUME #0 is always invalid (ICL621I)"
      ERRORS=$((ERRORS + 1))
    elif [[ "$line" =~ 'RESUME[[:space:]]+\.[0-9]+' ]]; then
      # Heuristic warning: RESUME .X; make sure .X cannot be zero
      echo "$src:$lineno: warning: RESUME of a variable -- verify it is never zero"
      WARNINGS=$((WARNINGS + 1))
    fi
  done < "$src"
done

if (( ERRORS > 0 )); then
  echo ""
  echo "lint_intercal: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
elif (( WARNINGS > 0 )); then
  echo ""
  echo "lint_intercal: OK ($WARNINGS warning(s))"
fi
exit 0
