#!/bin/zsh
# Verify DO INCLUDE "other.i" expands the named file inline at parse time.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: include of a small file expands; combined politeness ratio is OK.
TMPDIR=$(mktemp -d /tmp/test_include.XXXXXX)
cat > "$TMPDIR/lib.i" <<'EOF'
DO .9 <- #99
EOF
cat > "$TMPDIR/main.i" <<'EOF'
DO INCLUDE "lib.i"
DO .1 <- #5
DO .2 <- #6
DO .3 <- #7
PLEASE GIVE UP
EOF
BIN=$(mktemp /tmp/test_include.XXXXXX)
(cd "$TMPDIR" && zsh "$COMPILER" < main.i > "$BIN" 2>/dev/null)
chmod +x "$BIN" 2>/dev/null
if [[ -s "$BIN" ]] && "$BIN" >/dev/null 2>&1; then
  echo "PASS basic include compiles + runs"
  PASS=$((PASS + 1))
else
  echo "FAIL basic include"
  FAIL=$((FAIL + 1))
fi
rm -f "$BIN"
rm -rf "$TMPDIR"

# Test 2: cycle detection - file includes itself
TMPDIR=$(mktemp -d /tmp/test_include.XXXXXX)
cat > "$TMPDIR/recursive.i" <<'EOF'
DO INCLUDE "recursive.i"
DO .1 <- #5
PLEASE GIVE UP
EOF
ERR=$(mktemp /tmp/test_include.XXXXXX)
(cd "$TMPDIR" && zsh "$COMPILER" < recursive.i > /dev/null 2> "$ERR")
if grep -qE 'INCLUDE.*cycle|recursive' "$ERR" 2>/dev/null; then
  echo "PASS cycle detected"
  PASS=$((PASS + 1))
else
  echo "FAIL cycle should be detected"
  cat "$ERR" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
fi
rm -f "$ERR"
rm -rf "$TMPDIR"

# Test 3: missing include file produces a clear error
TMPDIR=$(mktemp -d /tmp/test_include.XXXXXX)
cat > "$TMPDIR/main.i" <<'EOF'
DO INCLUDE "missing.i"
DO .1 <- #5
PLEASE GIVE UP
EOF
ERR=$(mktemp /tmp/test_include.XXXXXX)
(cd "$TMPDIR" && zsh "$COMPILER" < main.i > /dev/null 2> "$ERR")
rc=$?
if (( rc != 0 )) && grep -qiE 'include|missing|not found' "$ERR" 2>/dev/null; then
  echo "PASS missing-file error"
  PASS=$((PASS + 1))
else
  echo "FAIL missing-file should error"
  cat "$ERR" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
fi
rm -f "$ERR"
rm -rf "$TMPDIR"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
