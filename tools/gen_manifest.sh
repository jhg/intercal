#!/bin/zsh
# Generate src/compiler/templates/manifest.txt with sha256 of every template.
# Run after regenerating templates or when adding new ones.
set -euo pipefail

ROOT_DIR="${0:A:h}/.."
MANIFEST="${ROOT_DIR}/src/compiler/templates/manifest.txt"

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

FIND_BIN=$(command -v find 2>/dev/null || true)
SORT_BIN=$(command -v sort 2>/dev/null || true)
WC_BIN=$(command -v wc 2>/dev/null || true)

cd "$ROOT_DIR"
TMPFILES=$(mktemp)
"$FIND_BIN" src/compiler/templates -type f -name '*.s' | "$SORT_BIN" > "$TMPFILES"

{
  echo "# Template integrity manifest"
  echo "# Format: <sha256>  <relative path>"
  echo "# Regenerate with tools/gen_manifest.sh"
  echo "# Verify with tools/verify_manifest.sh"
  while read -r f; do
    h=$(hash_of "$f")
    echo "$h  $f"
  done < "$TMPFILES"
} > "$MANIFEST"
rm -f "$TMPFILES"
echo "Wrote $("$WC_BIN" -l <"$MANIFEST") lines to $MANIFEST"
