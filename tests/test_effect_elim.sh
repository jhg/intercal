#!/bin/zsh
# Verify effect-driven runtime-check elimination: when a statement
# is statically proven not to raise E275, codegen skips emitting the
# cmp+b.hi check at the assignment.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: ASSIGN of small constant to .N (16-bit) — E275 impossible.
SRC1=$(mktemp /tmp/test_effelim.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC1" 2>/dev/null)
n_e275=$(echo "$asm" | grep -c "_rt_error_E275" 2>/dev/null)
n_e275=${n_e275:-0}
if (( n_e275 == 0 )); then
  echo "PASS small const: E275 check elided"
  PASS=$((PASS + 1))
else
  echo "FAIL small const: $n_e275 E275 checks remain"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC1"

# Test 2: ASSIGN of expression — E275 must remain (overflow possible).
SRC2=$(mktemp /tmp/test_effelim.XXXXXX)
cat > "$SRC2" <<'EOF'
PLEASE WRITE IN .1
DO .2 <- .1
DO .3 <- .1
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC2" 2>/dev/null)
n_e275=$(echo "$asm" | grep -c "_rt_error_E275" 2>/dev/null)
n_e275=${n_e275:-0}
if (( n_e275 >= 1 )); then
  echo "PASS dynamic value: E275 check kept ($n_e275)"
  PASS=$((PASS + 1))
else
  echo "FAIL dynamic value: E275 should be kept"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC2"

# Test 3: ASSIGN with bisect=0 disables the elimination
SRC3=$(mktemp /tmp/test_effelim.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
asm_unopt=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" --opt-bisect-limit=0 < "$SRC3" 2>/dev/null)
n_e275_unopt=$(echo "$asm_unopt" | grep -c "_rt_error_E275" 2>/dev/null)
n_e275_unopt=${n_e275_unopt:-0}
if (( n_e275_unopt >= 1 )); then
  echo "PASS bisect=0 restores E275 check"
  PASS=$((PASS + 1))
else
  echo "FAIL bisect=0: E275 still elided"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
