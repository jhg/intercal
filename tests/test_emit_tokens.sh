#!/bin/zsh
# Verify --emit-tokens dumps a token-level statement table
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

run_emit_tokens() {
  local name=$1
  local source=$2
  local expected_substrings=("${@:3}")

  local out
  out=$(zsh "$COMPILER" --emit-tokens < "$source" 2>&1)
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

# Test 1: a tiny linear program produces a clean token table
SRC1=$(mktemp /tmp/test_tokens.XXXXXX.i)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF
run_emit_tokens "linear program" "$SRC1" \
  "=== Token table ===" \
  "stmt   1:" \
  "ASSIGN" \
  "stmt   2:" \
  "GIVE_UP" \
  "PLEASE"
rm -f "$SRC1"

# Test 2: NEXT/RESUME label and modifier flags
SRC2=$(mktemp /tmp/test_tokens.XXXXXX.i)
cat > "$SRC2" <<'EOF'
DO .1 <- #1
DO (10) NEXT
PLEASE GIVE UP
(10) PLEASE RESUME #1
EOF
run_emit_tokens "NEXT/RESUME with label" "$SRC2" \
  "label 10" \
  "NEXT" \
  "RESUME"
rm -f "$SRC2"

# Test 3: NOT modifier surfaces
SRC3=$(mktemp /tmp/test_tokens.XXXXXX.i)
cat > "$SRC3" <<'EOF'
DO .1 <- #5
DON'T READ OUT .1
DO .2 <- #3
PLEASE GIVE UP
EOF
run_emit_tokens "NOT modifier" "$SRC3" \
  "NOT" \
  "READ_OUT"
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
