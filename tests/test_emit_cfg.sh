#!/bin/zsh
# Verify --emit-cfg dumps a control-flow graph representation
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

run_emit_cfg() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")

  local out
  out=$(zsh "$COMPILER" --emit-cfg < "$source" 2>&1)
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

cd "$SCRIPT_DIR"

# Test 1: a tiny linear program emits a single basic block
SRC1=$(mktemp /tmp/test_cfg.XXXXXX.i)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
run_emit_cfg "linear program" "$SRC1" \
  "=== Control flow graph ===" \
  "B0:" \
  "ASSIGN" \
  "GIVE_UP" \
  "-> exit"
rm -f "$SRC1"

# Test 2: a labeled statement starts a new basic block
SRC2=$(mktemp /tmp/test_cfg.XXXXXX.i)
cat > "$SRC2" <<'EOF'
DO .1 <- #1
DO (10) NEXT
DO .1 <- #2
PLEASE GIVE UP
(10) DO .1 <- #3
PLEASE RESUME #1
EOF
run_emit_cfg "NEXT and labeled block" "$SRC2" \
  "B0:" \
  "B1:" \
  "label 10" \
  "NEXT" \
  "RESUME"
rm -f "$SRC2"

# Test 3: COME FROM creates an edge
SRC3=$(mktemp /tmp/test_cfg.XXXXXX.i)
cat > "$SRC3" <<'EOF'
DO COME FROM (200)
DO .1 <- #5
PLEASE GIVE UP
(200) DO .2 <- #1
DO .3 <- #2
EOF
run_emit_cfg "COME FROM edge" "$SRC3" \
  "COME_FROM" \
  "label 200"
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
