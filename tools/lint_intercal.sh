#!/bin/zsh
# lint_intercal.sh - static checks for INTERCAL .i source files.
#
# Usage:
#   tools/lint_intercal.sh program.i [more.i ...]
#   find . -name '*.i' | xargs tools/lint_intercal.sh
#
# Files may include a magic comment to suppress specific checks:
#   DON'T NOTE LINT-SKIP: politeness labels resume
# Supported tokens: politeness, labels, resume, all
#
# Emits warnings/errors to stdout in the form:
#   <path>:<line>: <level>: <message>
#
# Exit code: 0 if no errors, 1 if any errors (warnings don't fail).
#
# Checks:
# - politeness ratio outside [1/5, 1/3] (error -- compiler would reject)
# - line label definition outside 1-65535 (error)
# - syslib label range 1000-1999 used as PROGRAM LABEL DEFINITION (warning)
# - RESUME #0 (error)
# - RESUME <variable> (warning, heuristic)
set -euo pipefail

ERRORS=0
WARNINGS=0

for src in "$@"; do
  if [[ ! -f "$src" ]]; then
    echo "$src: error: file not found"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Parse LINT-SKIP directive(s)
  SKIP_POLITENESS=0
  SKIP_LABELS=0
  SKIP_RESUME=0
  if grep -qE "DON'T NOTE LINT-SKIP:" "$src"; then
    skip_line=$(grep -E "DON'T NOTE LINT-SKIP:" "$src" | head -1)
    [[ "$skip_line" =~ 'all' ]] && { SKIP_POLITENESS=1; SKIP_LABELS=1; SKIP_RESUME=1; }
    [[ "$skip_line" =~ 'politeness' ]] && SKIP_POLITENESS=1
    [[ "$skip_line" =~ 'labels' ]] && SKIP_LABELS=1
    [[ "$skip_line" =~ 'resume' ]] && SKIP_RESUME=1
  fi

  # Auto-skip tests that intentionally exercise error paths
  case "$(basename "$src")" in
    test_errors_rude.i|test_errors_polite.i) SKIP_POLITENESS=1 ;;
    test_error_e621.i|test_error_e625.i)     SKIP_RESUME=1 ;;
    test_syslib.i|test_multiply.i|test_divide.i|test_stash.i) SKIP_LABELS=1 ;;
  esac

  # Count statements: lines starting with optional label then DO/PLEASE/DON'T
  total=$(grep -cE "^[[:space:]]*(\([0-9]+\)[[:space:]]*)?(PLEASE|DO|DON'T)" "$src" || true)
  polite=$(grep -cE "^[[:space:]]*(\([0-9]+\)[[:space:]]*)?PLEASE" "$src" || true)

  # Politeness check (only if stmt_count >= 5)
  if (( ! SKIP_POLITENESS )) && (( total >= 5 )); then
    if (( polite * 5 < total )); then
      echo "$src: error: insufficient politeness ($polite of $total statements use PLEASE; need >= $(( (total + 4) / 5 )))"
      ERRORS=$((ERRORS + 1))
    fi
    if (( polite * 3 > total )); then
      echo "$src: error: excessive politeness ($polite of $total statements use PLEASE; max $(( total / 3 )))"
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # Label DEFINITION range check (only parens at start of a statement = label def,
  # not NEXT targets like "DO (1030) NEXT" which use same syntax)
  if (( ! SKIP_LABELS )); then
    lineno=0
    while IFS= read -r line; do
      lineno=$((lineno + 1))
      # Match: optional leading whitespace, then (NUM), then DO/PLEASE/DON'T
      if [[ "$line" =~ '^[[:space:]]*\(([0-9]+)\)[[:space:]]+(PLEASE|DO|DONT)' ]]; then
        lbl="${match[1]}"
        if (( lbl < 1 || lbl > 65535 )); then
          echo "$src:$lineno: error: label ($lbl) outside permitted range 1-65535"
          ERRORS=$((ERRORS + 1))
        fi
        if (( lbl >= 1000 && lbl <= 1999 )); then
          case "$src" in
            *syslib*) ;;
            *) echo "$src:$lineno: warning: label ($lbl) in syslib-reserved range 1000-1999"
               WARNINGS=$((WARNINGS + 1)) ;;
          esac
        fi
      fi
    done < "$src"
  fi

  # RESUME checks
  if (( ! SKIP_RESUME )); then
    lineno=0
    while IFS= read -r line; do
      lineno=$((lineno + 1))
      if [[ "$line" =~ 'RESUME[[:space:]]+#0([^0-9]|$)' ]]; then
        echo "$src:$lineno: error: RESUME #0 is always invalid (ICL621I)"
        ERRORS=$((ERRORS + 1))
      elif [[ "$line" =~ 'RESUME[[:space:]]+\.[0-9]+' ]]; then
        echo "$src:$lineno: warning: RESUME of a variable -- verify it is never zero"
        WARNINGS=$((WARNINGS + 1))
      fi
    done < "$src"
  fi
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
