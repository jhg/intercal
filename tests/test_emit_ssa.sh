#!/bin/zsh
# Verify --emit-ssa builds SSA form from the parse tree and prints
# every variable definition with a fresh version number.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

run_emit_ssa() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")
  local out
  out=$(zsh "$COMPILER" --emit-ssa < "$source" 2>&1)
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

# Test 1: two assignments to .1 produce two SSA versions
SRC1=$(mktemp /tmp/test_ssa.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
DO .1 <- #6
PLEASE GIVE UP
EOF
run_emit_ssa "two assignments" "$SRC1" \
  "=== SSA form ===" \
  "spot_1.1 =" \
  "spot_1.2 =" \
  "GIVE_UP"
rm -f "$SRC1"

# Test 2: SSA invariants are reported
SRC2=$(mktemp /tmp/test_ssa.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO .2 <- #7
PLEASE GIVE UP
EOF
run_emit_ssa "invariants" "$SRC2" \
  "ssa values:" \
  "blocks:"
rm -f "$SRC2"

# Test 3: control-flow join with NEXT/RESUME shows block-parameter
SRC3=$(mktemp /tmp/test_ssa.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
DO (10) NEXT
DO .2 <- #6
DO .3 <- #7
PLEASE GIVE UP
(10) PLEASE RESUME #1
EOF
run_emit_ssa "control flow" "$SRC3" \
  "block B" \
  "RESUME"
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
