#!/bin/zsh
# Verify the minimal bytecode tier compiles and runs simple programs.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
BC_COMPILER="${ROOT_DIR}/src/bytecode/intercalc_bc.sh"
BC_VM="${ROOT_DIR}/src/bytecode/intercalc_vm.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: simple program produces correct Roman output via bytecode
SRC1=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #5
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC1" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "V" ]]; then
  echo "PASS bytecode V"
  PASS=$((PASS + 1))
else
  echo "FAIL bytecode V: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC1"

# Test 2: a slightly larger program
SRC2=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #42
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC2" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "XLII" ]]; then
  echo "PASS bytecode XLII"
  PASS=$((PASS + 1))
else
  echo "FAIL bytecode XLII: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC2"

# Test 3: out-of-subset programs error cleanly
SRC3=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC3" <<'EOF'
DO COME FROM (10)
DO .1 <- #5
DO GIVE UP
EOF
err=$(zsh "$BC_COMPILER" < "$SRC3" 2>&1 >/dev/null)
rc=$?
if (( rc != 0 )) && [[ "$err" == *"unsupported"* ]]; then
  echo "PASS bytecode rejects out-of-subset"
  PASS=$((PASS + 1))
else
  echo "FAIL out-of-subset should error"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
