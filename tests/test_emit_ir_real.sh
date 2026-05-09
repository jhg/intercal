#!/bin/zsh
# Verify --emit-ir-real produces a real three-address IR data
# structure (parallel arrays) populated from the parse tree,
# distinct from the read-only --emit-3addr / --emit-ir-full views.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

run_emit_ir_real() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")
  local out
  out=$(zsh "$COMPILER" --emit-ir-real < "$source" 2>&1)
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

# Test 1: expression breakdown into three-address form
SRC1=$(mktemp /tmp/test_ir_real.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- '#5 ~ #65535'
PLEASE GIVE UP
EOF
run_emit_ir_real "select expression" "$SRC1" \
  "=== IR (three-address) ===" \
  "ir_ops:" \
  "CONST" \
  "SELECT" \
  "STORE"
rm -f "$SRC1"

# Test 2: temporaries are numbered
SRC2=$(mktemp /tmp/test_ir_real.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO .2 <- #6
PLEASE GIVE UP
EOF
run_emit_ir_real "temps" "$SRC2" \
  "t0" \
  "t1"
rm -f "$SRC2"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
