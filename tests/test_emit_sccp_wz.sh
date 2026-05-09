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

rm -f "$SRC" "$SRC2"
echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
