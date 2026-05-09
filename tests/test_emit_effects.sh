#!/bin/zsh
# Verify --emit-effects performs per-statement static analysis of
# which ICL runtime errors each statement could raise.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

run_emit_effects() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")
  local out
  out=$(zsh "$COMPILER" --emit-effects < "$source" 2>&1)
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

# Test 1: ASSIGN can raise E275 (overflow on assignment)
SRC1=$(mktemp /tmp/test_eff.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
run_emit_effects "ASSIGN possible errors" "$SRC1" \
  "=== Effect / error analysis ===" \
  "ASSIGN" \
  "E275"
rm -f "$SRC1"

# Test 2: NEXT can raise E123 (stack overflow) and possibly E129 (undef label)
SRC2=$(mktemp /tmp/test_eff.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO (10) NEXT
DO .2 <- #6
DO .3 <- #7
PLEASE GIVE UP
(10) PLEASE RESUME #1
EOF
run_emit_effects "NEXT errors" "$SRC2" \
  "NEXT" \
  "E123"
rm -f "$SRC2"

# Test 3: GIVE_UP raises nothing (terminates)
SRC3=$(mktemp /tmp/test_eff.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
run_emit_effects "GIVE_UP no errors" "$SRC3" \
  "GIVE_UP" \
  "(none)"
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
