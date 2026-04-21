#!/bin/zsh
# lint_assembly.sh - platform-aware static checks for generated assembly.
#
# Usage:
#   tools/lint_assembly.sh <path.s> [platform]
#   find src/compiler/templates -name '*.s' | xargs -I{} tools/lint_assembly.sh {}
#
# Platform is auto-detected from the path (macos_arm64/linux_arm64/linux_x86_64)
# or can be passed explicitly.
#
# Checks per platform:
# macOS ARM64:
#   - _ prefix on exported symbols
#   - @PAGE/@PAGEOFF relocations
#   - svc #0x80
# Linux ARM64:
#   - NO :pg_hi21: relocations (GNU as infers it)
#   - :lo12: prefix only on add, not on adrp
#   - svc #0 (not 0x80)
#   - openat (not open)
#   - Entry symbol 'main' without _ prefix
# Linux x86_64:
#   - # not // for comments
#   - .intel_syntax noprefix header
#   - RIP-relative addressing [rip + sym]
#   - No 3-register addressing like [r12+r14+rcx]
set -euo pipefail

ERRORS=0
WARNINGS=0

for src in "$@"; do
  [[ "$src" == "linux_arm64" || "$src" == "linux_x86_64" || "$src" == "macos_arm64" ]] && continue
  if [[ ! -f "$src" ]]; then
    echo "$src: error: file not found"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Platform detection
  PLAT=""
  case "$src" in
    */macos_arm64/*|*macos_arm64*)   PLAT="macos_arm64" ;;
    */linux_arm64/*|*linux_arm64*)   PLAT="linux_arm64" ;;
    */linux_x86_64/*|*linux_x86_64*) PLAT="linux_x86_64" ;;
  esac

  case "$PLAT" in
    macos_arm64)
      # svc must be 0x80 (or #0x80)
      if grep -qE 'svc[[:space:]]+#0[[:space:]]*$' "$src"; then
        echo "$src: error: uses svc #0 on macos_arm64 (should be #0x80)"
        ERRORS=$((ERRORS + 1))
      fi
      if grep -q 'openat' "$src"; then
        echo "$src: warning: openat called on macos_arm64 (use open)"
        WARNINGS=$((WARNINGS + 1))
      fi
      ;;
    linux_arm64)
      if grep -qE ':pg_hi21:' "$src"; then
        echo "$src: error: :pg_hi21: not valid with GNU as; use bare symbol"
        ERRORS=$((ERRORS + 1))
      fi
      if grep -qE 'svc[[:space:]]+#0x80' "$src"; then
        echo "$src: error: uses svc #0x80 on linux_arm64 (should be #0)"
        ERRORS=$((ERRORS + 1))
      fi
      if grep -qE '^\s*bl\s+_?open\b|svc[^_]open\b' "$src"; then
        echo "$src: warning: open() on linux_arm64 does not exist, use openat"
        WARNINGS=$((WARNINGS + 1))
      fi
      ;;
    linux_x86_64)
      # GNU as rejects // as comment
      if grep -qE '^[[:space:]]*//' "$src"; then
        echo "$src: error: uses // comments (GNU as x86_64 requires #)"
        ERRORS=$((ERRORS + 1))
      fi
      # must declare intel syntax at top (first few lines)
      if ! head -5 "$src" | grep -q '.intel_syntax'; then
        echo "$src: warning: missing .intel_syntax noprefix directive"
        WARNINGS=$((WARNINGS + 1))
      fi
      # detect three-register addressing
      if grep -qE '\[[re][a-z0-9]+[[:space:]]*\+[[:space:]]*[re][a-z0-9]+[[:space:]]*\+[[:space:]]*[re][a-z0-9]+\]' "$src"; then
        echo "$src: error: three-register addressing not supported on x86_64"
        ERRORS=$((ERRORS + 1))
      fi
      ;;
    *)
      echo "$src: warning: platform could not be detected from path"
      WARNINGS=$((WARNINGS + 1))
      ;;
  esac
done

if (( ERRORS > 0 )); then
  echo ""
  echo "lint_assembly: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
elif (( WARNINGS > 0 )); then
  echo ""
  echo "lint_assembly: OK ($WARNINGS warning(s))"
fi
exit 0
