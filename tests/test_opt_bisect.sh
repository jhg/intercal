#!/bin/zsh
# Verify --opt-bisect-limit and --opt-bisect-verbose work
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# A program with at least one foldable constant + at least one peephole-eligible
# pattern. The COME FROM in test_come_from.i exercises peephole.
SRC=$(mktemp /tmp/test_bisect.XXXXXX)
# A program with several statements: codegen emits per-stmt fall-through
# 'b LABEL' before 'LABEL:' that the peephole pass eliminates. Each
# elimination is one bisect-checked transformation.
cat > "$SRC" <<'EOF'
DO .1 <- #5
DO .2 <- #6
DO .3 <- #7
DO .4 <- #8
PLEASE GIVE UP
EOF

# Test 1: --opt-bisect-verbose prints APPLY lines for each opt
ERR1=$(mktemp /tmp/test_bisect.XXXXXX)
zsh "$COMPILER" --opt-bisect-verbose < "$SRC" > /dev/null 2> "$ERR1"
if grep -q "BISECT: APPLY" "$ERR1" 2>/dev/null; then
  echo "PASS verbose mode"
  PASS=$((PASS + 1))
else
  echo "FAIL verbose mode: no BISECT lines on stderr"
  cat "$ERR1" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
fi

# Test 2: --opt-bisect-limit=0 disables every optimization (BISECT: SKIP lines)
ERR2=$(mktemp /tmp/test_bisect.XXXXXX)
zsh "$COMPILER" --opt-bisect-limit=0 --opt-bisect-verbose < "$SRC" > /dev/null 2> "$ERR2"
if grep -q "BISECT: SKIP" "$ERR2" 2>/dev/null; then
  echo "PASS limit=0 skips all"
  PASS=$((PASS + 1))
else
  echo "FAIL limit=0 skips all"
  FAIL=$((FAIL + 1))
fi

# Test 3: limit=N applies only first N
ERR3=$(mktemp /tmp/test_bisect.XXXXXX)
zsh "$COMPILER" --opt-bisect-limit=1 --opt-bisect-verbose < "$SRC" > /dev/null 2> "$ERR3"
n_apply=$(grep -c "BISECT: APPLY" "$ERR3" 2>/dev/null)
n_apply=${n_apply:-0}
n_skip=$(grep -c "BISECT: SKIP" "$ERR3" 2>/dev/null)
n_skip=${n_skip:-0}
if (( n_apply == 1 )) && (( n_skip >= 1 )); then
  echo "PASS limit=1 applies one, skips rest (apply=$n_apply skip=$n_skip)"
  PASS=$((PASS + 1))
else
  echo "FAIL limit=1: expected apply=1 + skip>=1, got apply=$n_apply skip=$n_skip"
  FAIL=$((FAIL + 1))
fi

# Test 4: even with limit=0 (no opts), program still compiles and runs
BIN=$(mktemp /tmp/test_bisect.XXXXXX)
zsh "$COMPILER" --opt-bisect-limit=0 < "$SRC" > "$BIN" 2>/dev/null
chmod +x "$BIN" 2>/dev/null
if "$BIN" 2>/dev/null >/dev/null; then
  echo "PASS limit=0 still produces working binary"
  PASS=$((PASS + 1))
else
  echo "FAIL limit=0: binary failed to run"
  FAIL=$((FAIL + 1))
fi
rm -f "$BIN"

rm -f "$SRC" "$ERR1" "$ERR2" "$ERR3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
