#!/bin/zsh
# Verify --emit-opt-summary produces a valid optimisation summary.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

# Test 1: a small program where all elisions fire.
SRC=$(mktemp /tmp/test_opt_summary.XXXXXX)
cat > "$SRC" <<'EOF'
DO .1 <- #5
PLEASE DO .2 <- .1
DO .3 <- #99
PLEASE DO READ OUT .3
DO STASH .1
DO .1 <- #99
DO RETRIEVE .1
PLEASE DO RESUME #1
DO GIVE UP
EOF
OUT=$(zsh "$COMPILER" --emit-opt-summary < "$SRC" 2>&1)

if [[ "$OUT" == *"=== Optimisation summary ==="* ]]; then
  echo "PASS opt-summary header"
  PASS=$((PASS + 1))
else
  echo "FAIL header missing"
  FAIL=$((FAIL + 1))
fi

if [[ "$OUT" == *"E275 elided (cmp+b.hi skipped):   4 / 4"* ]]; then
  echo "PASS E275 elision count: 4 / 4"
  PASS=$((PASS + 1))
else
  echo "FAIL E275 count missing or wrong"
  echo "$OUT"
  FAIL=$((FAIL + 1))
fi

if [[ "$OUT" == *"E621 elided (cbz skipped):        1 / 1"* ]]; then
  echo "PASS E621 elision count: 1 / 1"
  PASS=$((PASS + 1))
else
  echo "FAIL E621 count missing"
  FAIL=$((FAIL + 1))
fi

if [[ "$OUT" == *"E436 elided (empty-stash skip):   1 / 1"* ]]; then
  echo "PASS E436 elision count: 1 / 1"
  PASS=$((PASS + 1))
else
  echo "FAIL E436 count missing"
  FAIL=$((FAIL + 1))
fi

rm -f "$SRC"
echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
