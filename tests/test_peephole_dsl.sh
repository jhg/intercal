#!/bin/zsh
# Verify the declarative peephole rule compiler produces correct code.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
PASS=0
FAIL=0

cd "$ROOT_DIR"

# Test 1: gen_peephole.sh runs cleanly
GENOUT=$(mktemp /tmp/test_pdsl.XXXXXX)
if zsh tools/gen_peephole.sh > "$GENOUT" 2>&1; then
  echo "PASS gen_peephole runs"
  PASS=$((PASS + 1))
else
  echo "FAIL gen_peephole errored"
  cat "$GENOUT"
  FAIL=$((FAIL + 1))
fi

# Test 2: generated file defines peephole_apply_rules
if grep -q "peephole_apply_rules()" "$GENOUT"; then
  echo "PASS function defined"
  PASS=$((PASS + 1))
else
  echo "FAIL function not defined"
  FAIL=$((FAIL + 1))
fi

# Test 3: at least three rules expanded (matching three rules in rules.peep)
n_rules=$(grep -c "# Rule:" "$GENOUT")
if (( n_rules >= 3 )); then
  echo "PASS at least 3 rules expanded ($n_rules)"
  PASS=$((PASS + 1))
else
  echo "FAIL only $n_rules rules expanded"
  FAIL=$((FAIL + 1))
fi

# Test 4: each rule references opt_bisect_check
n_bisect=$(grep -c "opt_bisect_check 'peephole_" "$GENOUT")
if (( n_bisect >= 3 )); then
  echo "PASS bisect gates present ($n_bisect)"
  PASS=$((PASS + 1))
else
  echo "FAIL only $n_bisect bisect gates"
  FAIL=$((FAIL + 1))
fi

# Test 5: source the generated file in a subshell with stub opt_bisect_check
# and verify peephole_apply_rules can be called.
TESTSCRIPT=$(mktemp /tmp/test_pdsl.XXXXXX)
cat > "$TESTSCRIPT" <<'EOF'
opt_bisect_check() { return 0 }  # always allow
source $1
typeset -i skip=0
typeset cur="  b _foo"
typeset lookahead="_foo:"
peephole_apply_rules
echo "skip=$skip"
EOF
out=$(zsh "$TESTSCRIPT" "$GENOUT")
if [[ "$out" == "skip=1" ]]; then
  echo "PASS branch_to_next rule fires correctly"
  PASS=$((PASS + 1))
else
  echo "FAIL branch_to_next: expected skip=1, got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$TESTSCRIPT" "$GENOUT"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
