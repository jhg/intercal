#!/bin/zsh
# Verify that every template in src/compiler/templates matches the
# sha256 recorded in manifest.txt. Fails with nonzero exit if any
# file is missing, added, or modified.
set -euo pipefail

ROOT_DIR="${0:A:h}/.."
MANIFEST="${ROOT_DIR}/src/compiler/templates/manifest.txt"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: $MANIFEST not found. Run tools/gen_manifest.sh first." >&2
  exit 1
fi

SHASUM_BIN=$(command -v shasum 2>/dev/null || true)
SHA256SUM_BIN=$(command -v sha256sum 2>/dev/null || true)
AWK_BIN=$(command -v awk 2>/dev/null || true)
if [[ -n "$SHASUM_BIN" ]]; then
  hash_of() { "$SHASUM_BIN" -a 256 "$1" | "$AWK_BIN" '{print $1}' ; }
elif [[ -n "$SHA256SUM_BIN" ]]; then
  hash_of() { "$SHA256SUM_BIN" "$1" | "$AWK_BIN" '{print $1}' ; }
else
  echo "ERROR: neither shasum nor sha256sum available" >&2
  exit 1
fi

cd "$ROOT_DIR"
FAIL=0
declare -A expected
while IFS= read -r line; do
  [[ "$line" =~ ^# || -z "$line" ]] && continue
  hash="${line%% *}"
  path="${line##* }"
  expected[$path]=$hash
done < "$MANIFEST"

# Check every file in the manifest exists and matches
for path hash in ${(kv)expected}; do
  if [[ ! -f "$path" ]]; then
    echo "MISSING $path"
    FAIL=$((FAIL + 1))
    continue
  fi
  actual=$(hash_of "$path")
  if [[ "$actual" != "$hash" ]]; then
    echo "MODIFIED $path"
    echo "  expected: $hash"
    echo "  actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
done

# Check no untracked .s templates exist
FIND_BIN=$(command -v find 2>/dev/null || true)
SORT_BIN=$(command -v sort 2>/dev/null || true)
if [[ -n "$FIND_BIN" && -n "$SORT_BIN" ]]; then
  TMPFILES=$(mktemp)
  "$FIND_BIN" src/compiler/templates -type f -name '*.s' | "$SORT_BIN" > "$TMPFILES"
  while IFS= read -r f; do
    if [[ -z "${expected[$f]+x}" ]]; then
      echo "EXTRA $f (not in manifest)"
      FAIL=$((FAIL + 1))
    fi
  done < "$TMPFILES"
  rm -f "$TMPFILES"
fi

if [[ $FAIL -eq 0 ]]; then
  echo "manifest OK: ${#expected[@]} templates verified"
  exit 0
else
  echo "manifest FAIL: $FAIL problems"
  exit 1
fi
