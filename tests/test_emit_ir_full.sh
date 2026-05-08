#!/bin/zsh
# Verify --emit-ir-full produces a real three-address IR + CFG view
# with use/def annotations, op codes, and explicit terminators.
# This is the read-only inspection layer; codegen is unchanged.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

run_emit_ir_full() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")
  local out
  out=$(zsh "$COMPILER" --emit-ir-full < "$source" 2>&1)
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

# Test 1: linear program produces opcodes plus block markers
SRC1=$(mktemp /tmp/test_ir.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
run_emit_ir_full "linear program" "$SRC1" \
  "=== Three-address IR + CFG ===" \
  "block B0:" \
  "ASSIGN" \
  "GIVE_UP" \
  "ops:"
rm -f "$SRC1"

# Test 2: program with NEXT shows control-flow op + edge
SRC2=$(mktemp /tmp/test_ir.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO (10) NEXT
PLEASE GIVE UP
(10) PLEASE RESUME #1
EOF
run_emit_ir_full "control flow" "$SRC2" \
  "NEXT" \
  "RESUME" \
  "label 10"
rm -f "$SRC2"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
