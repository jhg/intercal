#!/bin/zsh
# Verify effect-driven elimination extends beyond E275 to E621 and E436.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: RESUME #1 (literal nonzero) -> E621 check elided
SRC1=$(mktemp /tmp/test_eff_more.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #1
DO (10) NEXT
DO .2 <- #6
DO .3 <- #7
PLEASE GIVE UP
(10) PLEASE RESUME #1
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC1" 2>/dev/null)
n=$(echo "$asm" | grep -c "_rt_error_E621" 2>/dev/null)
n=${n:-0}
if (( n == 0 )); then
  echo "PASS RESUME #1 elides E621 check"
  PASS=$((PASS + 1))
else
  echo "FAIL RESUME #1: still $n E621 checks"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC1"

# Test 2: STASH then RETRIEVE on the same var -> E436 elided
SRC2=$(mktemp /tmp/test_eff_more.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO STASH .1
DO .1 <- #99
DO RETRIEVE .1
DO .9 <- #9
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC2" 2>/dev/null)
n=$(echo "$asm" | grep -c "_rt_error_E436" 2>/dev/null)
n=${n:-0}
if (( n == 0 )); then
  echo "PASS STASH+RETRIEVE elides E436 check"
  PASS=$((PASS + 1))
else
  echo "FAIL E436: still $n checks"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC2"

# Test 3: bare RETRIEVE without prior STASH must keep the check
SRC3=$(mktemp /tmp/test_eff_more.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
DO RETRIEVE .1
DO .8 <- #8
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC3" 2>/dev/null)
n=$(echo "$asm" | grep -c "_rt_error_E436" 2>/dev/null)
n=${n:-0}
if (( n >= 1 )); then
  echo "PASS bare RETRIEVE keeps E436 check ($n)"
  PASS=$((PASS + 1))
else
  echo "FAIL bare RETRIEVE: E436 elided unsoundly"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
