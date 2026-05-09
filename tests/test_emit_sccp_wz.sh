#!/bin/zsh
# Verify --emit-sccp-wz produces a valid Wegman-Zadeck SCCP dump.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

# Test 1: chain copy propagates the constant through every var version.
SRC=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC" <<'EOF'
DO .1 <- #5
DO .2 <- .1
PLEASE DO .3 <- .2
DO READ OUT .3
DO GIVE UP
EOF
OUT=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC" 2>&1)

if [[ "$OUT" == *"=== Wegman-Zadeck SCCP ==="* ]]; then
  echo "PASS sccp-wz dump header"
  PASS=$((PASS + 1))
else
  echo "FAIL header missing"
  FAIL=$((FAIL + 1))
fi

if [[ "$OUT" == *"spot_3"*"= CONST(5)"* ]]; then
  echo "PASS chain copy propagates to spot_3 = CONST(5)"
  PASS=$((PASS + 1))
else
  echo "FAIL spot_3 not propagated"
  echo "$OUT"
  FAIL=$((FAIL + 1))
fi

# Test 2: BOTTOM for an expression we don't model.
SRC2=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO .2 <- '.1 ~ .1'
PLEASE DO READ OUT .2
DO GIVE UP
EOF
OUT2=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC2" 2>&1)

if [[ "$OUT2" == *"spot_2"*"= BOTTOM"* ]]; then
  echo "PASS BOTTOM for unmodelled expression"
  PASS=$((PASS + 1))
else
  echo "FAIL BOTTOM not reported for spot_2"
  echo "$OUT2"
  FAIL=$((FAIL + 1))
fi

# Test 3: lattice values per statement are reported in the dump.
if [[ "$OUT" == *"stmt  1: spot_1       = CONST(5)"* ]]; then
  echo "PASS per-statement lattice listing"
  PASS=$((PASS + 1))
else
  echo "FAIL per-statement listing missing"
  FAIL=$((FAIL + 1))
fi

# Test 4: dead code after GIVE UP is not marked executable.
SRC3=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
PLEASE DO .2 <- #7
DO READ OUT .1
PLEASE DO READ OUT .2
DO GIVE UP
DO .3 <- #99
DO .4 <- #88
DON'T NOTE filler
EOF
OUT3=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC3" 2>&1)
exec_count=$(echo "$OUT3" | grep -oE 'executable statements: [0-9]+' | grep -oE '[0-9]+')
# 5 reachable (1..5), 3 unreachable (6..8). Expect 5.
if [[ "$exec_count" == "5" ]]; then
  echo "PASS dead code after GIVE UP excluded (executable=5)"
  PASS=$((PASS + 1))
else
  echo "FAIL expected 5 executable, got [$exec_count]"
  FAIL=$((FAIL + 1))
fi

# Test 5: syslib 1009 (16-bit add) is evaluated in the lattice when both
# inputs are CONST.
SRC4=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC4" <<'EOF'
DO .1 <- #5
PLEASE DO .2 <- #7
DO (1009) NEXT
DO READ OUT .3
PLEASE DO GIVE UP
DON'T NOTE filler
EOF
OUT4=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC4" 2>&1)
if [[ "$OUT4" == *"spot_3       = CONST(12)"* ]]; then
  echo "PASS syslib 1009 evaluated to CONST(12)"
  PASS=$((PASS + 1))
else
  echo "FAIL syslib 1009 not folded"
  echo "$OUT4"
  FAIL=$((FAIL + 1))
fi
if [[ "$OUT4" == *"spot_4       = CONST(1)"* ]]; then
  echo "PASS syslib 1009 overflow flag CONST(1) (no overflow)"
  PASS=$((PASS + 1))
else
  echo "FAIL overflow flag not modelled"
  FAIL=$((FAIL + 1))
fi

# Test 6: syslib 1010 (subtract) folded.
SRC5=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC5" <<'EOF'
DO .1 <- #20
PLEASE DO .2 <- #5
DO (1010) NEXT
DO READ OUT .3
PLEASE DO GIVE UP
DON'T NOTE filler
EOF
OUT5=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC5" 2>&1)
if [[ "$OUT5" == *"spot_3       = CONST(15)"* ]]; then
  echo "PASS syslib 1010 evaluated to CONST(15)"
  PASS=$((PASS + 1))
else
  echo "FAIL syslib 1010 not folded"
  FAIL=$((FAIL + 1))
fi

# Test 7: COME FROM source edges flow lattice values through the
# meet at the COME FROM destination.
SRC6=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC6" <<'EOF'
DO .1 <- #5
(10) DO .1 <- #99
PLEASE DO COME FROM (10)
DO READ OUT .1
PLEASE DO GIVE UP
DON'T NOTE filler1
DON'T NOTE filler2
EOF
OUT6=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC6" 2>&1)
# Statement (10) sets spot_1 = CONST(99). After (10) runs, control
# transfers via COME FROM to "stmt 4 = READ OUT .1". preds[4] now
# includes stmt 2 (the labelled (10)). Meet flows CONST(99) into
# stmt 4. Without the COME FROM source edge, the meet at stmt 4
# would only see stmt 3's outgoing (the COME FROM line itself).
if [[ "$OUT6" == *"stmt  4: spot_1       = CONST(99)"* ]]; then
  echo "PASS COME FROM source edge flows CONST(99) to dest"
  PASS=$((PASS + 1))
else
  echo "FAIL COME FROM source edge not propagated"
  echo "$OUT6" | head -20
  FAIL=$((FAIL + 1))
fi

# Test 8: syslib 1500 (32-bit add) folded.
SRC7=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC7" <<'EOF'
DO :1 <- #1000
PLEASE DO :2 <- #2345
DO (1500) NEXT
DO READ OUT :3
PLEASE DO GIVE UP
DON'T NOTE filler
EOF
OUT7=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC7" 2>&1)
if [[ "$OUT7" == *"twospot_3    = CONST(3345)"* ]]; then
  echo "PASS syslib 1500 (32-bit add) -> CONST(3345)"
  PASS=$((PASS + 1))
else
  echo "FAIL 1500 not folded"
  FAIL=$((FAIL + 1))
fi

# Test 9: syslib 1530 (16x16 -> 32-bit multiply) folded.
SRC8=$(mktemp /tmp/test_sccp_wz.XXXXXX)
cat > "$SRC8" <<'EOF'
DO .1 <- #5
PLEASE DO .2 <- #3
DO (1530) NEXT
DO READ OUT :1
PLEASE DO GIVE UP
DON'T NOTE filler
EOF
OUT8=$(zsh "$COMPILER" --emit-sccp-wz < "$SRC8" 2>&1)
if [[ "$OUT8" == *"twospot_1    = CONST(15)"* ]]; then
  echo "PASS syslib 1530 (16x16 -> 32-bit multiply) -> CONST(15)"
  PASS=$((PASS + 1))
else
  echo "FAIL 1530 not folded"
  FAIL=$((FAIL + 1))
fi

rm -f "$SRC" "$SRC2" "$SRC3" "$SRC4" "$SRC5" "$SRC6" "$SRC7" "$SRC8"
echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
