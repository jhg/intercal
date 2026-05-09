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

# Test 4: forward-only NEXT in a loop-free program -> E123 check elided
SRC_E123=$(mktemp /tmp/test_eff_more.XXXXXX)
cat > "$SRC_E123" <<'EOF'
DO .1 <- #5
PLEASE DO (1009) NEXT
DO READ OUT .3
DO GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC_E123" 2>/dev/null)
n=$(echo "$asm" | grep -c "_rt_error_E123" 2>/dev/null)
n=${n:-0}
if (( n == 0 )); then
  echo "PASS forward-only NEXT in loop-free program elides E123"
  PASS=$((PASS + 1))
else
  echo "FAIL E123 not elided: $n references in emitted asm"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_E123"

# Test 5: backward NEXT (recursion) keeps the E123 check.
SRC_E123B=$(mktemp /tmp/test_eff_more.XXXXXX)
cat > "$SRC_E123B" <<'EOF'
        DO .1 <- #1
(10)    DO (10) NEXT
        PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC_E123B" 2>/dev/null)
n=$(echo "$asm" | grep -c "_rt_error_E123" 2>/dev/null)
n=${n:-0}
if (( n >= 1 )); then
  echo "PASS backward NEXT keeps E123 check ($n references)"
  PASS=$((PASS + 1))
else
  echo "FAIL backward NEXT should KEEP E123 check"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_E123B"

# Test 6: ARRAY_DIM with literal nonzero -> E240 elided.
SRC_E240=$(mktemp /tmp/test_eff_more.XXXXXX)
cat > "$SRC_E240" <<'EOF'
PLEASE DO ,1 <- #5
DO READ OUT #1
DO GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC_E240" 2>/dev/null)
n=$(echo "$asm" | grep -c "_rt_error_E240" 2>/dev/null)
n=${n:-0}
if (( n == 0 )); then
  echo "PASS literal nonzero ARRAY_DIM elides E240"
  PASS=$((PASS + 1))
else
  echo "FAIL E240 not elided: $n references"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_E240"

# Test 7: ARRAY_DIM with non-literal dim keeps E240 check.
SRC_E240B=$(mktemp /tmp/test_eff_more.XXXXXX)
cat > "$SRC_E240B" <<'EOF'
DO .1 <- #5
PLEASE DO ,1 <- .1
DO READ OUT #1
DO GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC_E240B" 2>/dev/null)
n=$(echo "$asm" | grep -c "_rt_error_E240" 2>/dev/null)
n=${n:-0}
if (( n >= 1 )); then
  echo "PASS non-literal ARRAY_DIM keeps E240 check ($n)"
  PASS=$((PASS + 1))
else
  echo "FAIL non-literal should keep E240"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_E240B"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
