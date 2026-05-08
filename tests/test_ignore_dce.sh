#!/bin/zsh
# Verify ignore-flag DCE: variables never IGNORE'd skip the runtime
# _ign-flag check at assignment.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: program with no IGNORE/REMEMBER should produce assembly that
# does NOT contain `_spot_*_ign@PAGE` references for the assigned vars.
SRC1=$(mktemp /tmp/test_ig_dce.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC1" 2>/dev/null)
n_ign=$(echo "$asm" | grep -c "_spot_1_ign@PAGE" 2>/dev/null)
n_ign=${n_ign:-0}
if (( n_ign == 0 )); then
  echo "PASS no IGNORE -> _spot_1_ign references dropped"
  PASS=$((PASS + 1))
else
  echo "FAIL no IGNORE: still $n_ign references to _spot_1_ign"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC1"

# Test 2: program WITH IGNORE on .1 must keep the check on .1
SRC2=$(mktemp /tmp/test_ig_dce.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO IGNORE .1
DO .1 <- #6
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC2" 2>/dev/null)
n_ign=$(echo "$asm" | grep -c "_spot_1_ign@PAGE" 2>/dev/null)
n_ign=${n_ign:-0}
if (( n_ign > 0 )); then
  echo "PASS IGNORE present -> _spot_1_ign references kept ($n_ign)"
  PASS=$((PASS + 1))
else
  echo "FAIL IGNORE present: dropped check unsoundly"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC2"

# Test 3: mixed: IGNORE only on .2, .1 should drop check, .2 should keep
SRC3=$(mktemp /tmp/test_ig_dce.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
DO IGNORE .2
DO .1 <- #6
DO .2 <- #7
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC3" 2>/dev/null)
n1=$(echo "$asm" | grep -c "_spot_1_ign@PAGE" 2>/dev/null)
n2=$(echo "$asm" | grep -c "_spot_2_ign@PAGE" 2>/dev/null)
n1=${n1:-0}
n2=${n2:-0}
if (( n1 == 0 && n2 > 0 )); then
  echo "PASS mixed: .1 dropped ($n1), .2 kept ($n2)"
  PASS=$((PASS + 1))
else
  echo "FAIL mixed: .1=$n1 (want 0), .2=$n2 (want >0)"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
