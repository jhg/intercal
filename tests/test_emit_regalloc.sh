#!/bin/zsh
# Verify --emit-regalloc computes live intervals on SSA values and
# applies Poletto-Sarkar linear-scan over them.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

run_emit_regalloc() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")
  local out
  out=$(zsh "$COMPILER" --emit-regalloc < "$source" 2>&1)
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

# Test 1: program with two vars produces a live-interval table
SRC1=$(mktemp /tmp/test_ralloc.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
DO .2 <- #6
DO .3 <- .1
PLEASE GIVE UP
EOF
run_emit_regalloc "two vars" "$SRC1" \
  "=== Liveness + linear-scan ===" \
  "live intervals:" \
  "spot_1.1" \
  "spot_2.1" \
  "spot_3.1"
rm -f "$SRC1"

# Test 2: pressure exceeds R triggers a spill
SRC2=$(mktemp /tmp/test_ralloc.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #1
DO .2 <- #2
DO .3 <- #3
PLEASE STASH .1
DO .4 <- #4
DO .5 <- #5
DO .6 <- #6
DO .7 <- .1
PLEASE GIVE UP
EOF
run_emit_regalloc "spill" "$SRC2" \
  "registers:" \
  "active set"
rm -f "$SRC2"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
