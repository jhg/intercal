#!/bin/zsh
# Verify --time-report prints per-phase timing breakdown
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: --time-report produces output containing each expected phase name
SRC1=$(mktemp /tmp/test_time.XXXXXX.i)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
PLEASE GIVE UP
EOF

OUT1=$(mktemp /tmp/test_time.XXXXXX.bin)
ERR1=$(mktemp /tmp/test_time.XXXXXX.err)
zsh "$COMPILER" --time-report < "$SRC1" > "$OUT1" 2> "$ERR1"
rc=$?

if (( rc != 0 )); then
  echo "FAIL phase names: compiler exited $rc"
  echo "  stderr:"
  cat "$ERR1" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
else
  errtext=$(cat "$ERR1")
  missing=""
  for phase in tokenize politeness labels come_from syslib flag_checks codegen peephole; do
    if [[ "$errtext" != *"$phase"* ]]; then
      missing+=" $phase"
    fi
  done
  if [[ -z "$missing" ]]; then
    echo "PASS phase names"
    PASS=$((PASS + 1))
  else
    echo "FAIL phase names: missing$missing"
    echo "  stderr:"
    echo "$errtext" | sed 's/^/    /'
    FAIL=$((FAIL + 1))
  fi
fi

# Test 2: header line "Compile-time breakdown" is present
if grep -q "Compile-time breakdown" "$ERR1" 2>/dev/null; then
  echo "PASS header line"
  PASS=$((PASS + 1))
else
  echo "FAIL header line: not in stderr"
  FAIL=$((FAIL + 1))
fi

# Test 3: time format "phase_name N.NNN s"
if grep -qE '^[[:space:]]+[a-z_]+[[:space:]]+[0-9]+\.[0-9]+[[:space:]]*s' "$ERR1" 2>/dev/null; then
  echo "PASS time format"
  PASS=$((PASS + 1))
else
  echo "FAIL time format: lines not 'phase_name N.NNN s'"
  echo "  stderr:"
  cat "$ERR1" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
fi

# Test 4: binary still gets produced (output goes to stdout normally)
if [[ -s "$OUT1" ]]; then
  echo "PASS binary produced"
  PASS=$((PASS + 1))
else
  echo "FAIL binary produced: stdout empty"
  FAIL=$((FAIL + 1))
fi

rm -f "$SRC1" "$OUT1" "$ERR1"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
