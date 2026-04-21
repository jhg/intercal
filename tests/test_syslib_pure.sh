#!/bin/zsh
# Verify pure INTERCAL syslib produces same results as native syslib
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

compare_syslib() {
  local name=$1 source=$2
  local bin_native=$(mktemp /tmp/intercal_native.XXXXXX)
  local bin_pure=$(mktemp /tmp/intercal_pure.XXXXXX)

  zsh "$COMPILER" < "$source" > "$bin_native" 2>/dev/null
  zsh "$COMPILER" --pure-syslib < "$source" > "$bin_pure" 2>/dev/null

  chmod +x "$bin_native" "$bin_pure" 2>/dev/null

  local out_native out_pure
  out_native=$("$bin_native" 2>/dev/null) || true
  out_pure=$("$bin_pure" 2>/dev/null) || true

  if [[ "$out_native" == "$out_pure" ]]; then
    echo "PASS $name (native=$out_native pure=$out_pure)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name"
    echo "  native: [$out_native]"
    echo "  pure:   [$out_pure]"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$bin_native" "$bin_pure"
}

cd "$SCRIPT_DIR"

echo "Comparing native vs pure INTERCAL syslib..."
echo ""

compare_syslib "add_5_3" test_syslib.i
compare_syslib "multiply_7_6" test_multiply.i
compare_syslib "divide_42_6" test_divide.i

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
