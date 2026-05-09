#!/bin/zsh
# Verify --emit-sccp performs sparse conditional constant propagation
# and reports per-variable lattice values across the program.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

run_emit_sccp() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")
  local out
  out=$(zsh "$COMPILER" --emit-sccp < "$source" 2>&1)
  local rc=$?
  if (( rc != 0 )); then
    echo "FAIL $name: compiler exited $rc"
    FAIL=$((FAIL + 1))
    return
  fi
  local missing=""
  local s
  for s in "${expected_substrings[@]}"; do
    if [[ "$out" != *"$s"* ]]; then
      missing+="    expected: $s"$'\n'
    fi
  done
  if [[ -z "$missing" ]]; then
    echo "PASS $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name"
    echo "$missing"
    echo "  got:"
    echo "$out" | sed 's/^/    /'
    FAIL=$((FAIL + 1))
  fi
}

# Test 1: constant assignment is detected as CONST
SRC1=$(mktemp /tmp/test_sccp.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
DO .2 <- #10
PLEASE GIVE UP
EOF
run_emit_sccp "constant tracking" "$SRC1" \
  "=== SCCP results ===" \
  "spot_1.1 = CONST(5)" \
  "spot_2.1 = CONST(10)"
rm -f "$SRC1"

# Test 2: assignment from another variable propagates the constant
SRC2=$(mktemp /tmp/test_sccp.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #7
DO .2 <- .1
PLEASE GIVE UP
EOF
run_emit_sccp "var-to-var constant prop" "$SRC2" \
  "spot_1.1 = CONST(7)" \
  "spot_2.1 ="
rm -f "$SRC2"

# Test 3: WRITE IN result is BOTTOM (runtime input)
SRC3=$(mktemp /tmp/test_sccp.XXXXXX)
cat > "$SRC3" <<'EOF'
PLEASE WRITE IN .1
DO .2 <- #9
DO .3 <- #2
PLEASE GIVE UP
EOF
run_emit_sccp "runtime input is bottom" "$SRC3" \
  "spot_1.1 = BOTTOM" \
  "spot_2.1 = CONST(9)"
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
