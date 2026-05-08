#!/bin/zsh
# Verify the compiler warns about unreferenced labels (proposal #7
# reframed: in our codegen INTERCAL labels are resolved at compile
# time and never become assembly symbols, so there is nothing to
# eliminate; instead we emit a warning when a label is statically
# proven dead, which is the analogous user-facing benefit).
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: program with one referenced + one unreferenced label.
# The unreferenced label triggers the warning; the referenced one does not.
SRC1=$(mktemp /tmp/test_lbl_dce.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
DO (10) NEXT
DO .2 <- #6
PLEASE GIVE UP
(10) PLEASE RESUME #1
(20) DO NOTE THIS IS UNREFERENCED
EOF
ERR1=$(mktemp /tmp/test_lbl_dce.XXXXXX)
zsh "$COMPILER" < "$SRC1" > /dev/null 2> "$ERR1"
if grep -qE 'ICL.*W.*LABEL 20' "$ERR1" 2>/dev/null; then
  echo "PASS warns on unreferenced label 20"
  PASS=$((PASS + 1))
else
  echo "FAIL no warning for label 20"
  echo "  stderr:"
  cat "$ERR1" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
fi
# And NOT for label 10 (referenced via NEXT)
if grep -qE 'ICL.*W.*LABEL 10' "$ERR1" 2>/dev/null; then
  echo "FAIL false-positive on label 10"
  FAIL=$((FAIL + 1))
else
  echo "PASS no false positive on label 10"
  PASS=$((PASS + 1))
fi
rm -f "$SRC1" "$ERR1"

# Test 2: COME FROM-targeted labels are referenced
SRC2=$(mktemp /tmp/test_lbl_dce.XXXXXX)
cat > "$SRC2" <<'EOF'
DO COME FROM (200)
DO .1 <- #5
PLEASE GIVE UP
(200) DO .2 <- #1
DO .3 <- #2
EOF
ERR2=$(mktemp /tmp/test_lbl_dce.XXXXXX)
zsh "$COMPILER" < "$SRC2" > /dev/null 2> "$ERR2"
if grep -qE 'ICL.*W.*LABEL 200' "$ERR2" 2>/dev/null; then
  echo "FAIL false-positive on COME FROM target"
  FAIL=$((FAIL + 1))
else
  echo "PASS COME FROM target not flagged"
  PASS=$((PASS + 1))
fi
rm -f "$SRC2" "$ERR2"

# Test 3: warning is non-fatal (compilation succeeds)
SRC3=$(mktemp /tmp/test_lbl_dce.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
(20) PLEASE NOTE THIS IS UNREFERENCED
EOF
BIN=$(mktemp /tmp/test_lbl_dce.XXXXXX)
zsh "$COMPILER" < "$SRC3" > "$BIN" 2>/dev/null
chmod +x "$BIN" 2>/dev/null
if [[ -s "$BIN" ]] && "$BIN" >/dev/null 2>&1; then
  echo "PASS warning is non-fatal"
  PASS=$((PASS + 1))
else
  echo "FAIL warning treated as error"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3" "$BIN"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
