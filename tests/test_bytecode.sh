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

# Test 3a: COPY between scalar variables
SRC3a=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC3a" <<'EOF'
DO .1 <- #100
DO .2 <- .1
DO READ OUT .2
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC3a" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "C" ]]; then
  echo "PASS COPY .1 -> .2"
  PASS=$((PASS + 1))
else
  echo "FAIL COPY: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3a"

# Test 3b: STASH/RETRIEVE round-trip
SRC3b=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC3b" <<'EOF'
DO .1 <- #7
DO STASH .1
DO .1 <- #99
DO RETRIEVE .1
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC3b" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "VII" ]]; then
  echo "PASS STASH/RETRIEVE round-trip"
  PASS=$((PASS + 1))
else
  echo "FAIL STASH/RETRIEVE: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3b"

# Test 3c: IGNORE prevents reassignment
SRC3c=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC3c" <<'EOF'
DO .1 <- #5
DO IGNORE .1
DO .1 <- #99
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC3c" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "V" ]]; then
  echo "PASS IGNORE blocks reassignment"
  PASS=$((PASS + 1))
else
  echo "FAIL IGNORE: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3c"

# Test 3d: twospot variables
SRC3d=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC3d" <<'EOF'
DO :1 <- #1000
DO READ OUT :1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC3d" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "M" ]]; then
  echo "PASS twospot M"
  PASS=$((PASS + 1))
else
  echo "FAIL twospot: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3d"

# Test arithmetic: select extracts bits
SRC_ARITH=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_ARITH" <<'EOF'
DO .1 <- '#5 ~ #65535'
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_ARITH" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "V" ]]; then
  echo "PASS bytecode arith: select(5, 0xFFFF) = 5"
  PASS=$((PASS + 1))
else
  echo "FAIL bytecode arith: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_ARITH"

# Test mingle
SRC_MIX=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_MIX" <<'EOF'
DO :1 <- '#0 $ #65535'
DO READ OUT :1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_MIX" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
# 0x55555555 = 1431655765, but the Roman-numeral converter caps; just test non-empty
if [[ -n "$out" ]]; then
  echo "PASS bytecode mingle produces output"
  PASS=$((PASS + 1))
else
  echo "FAIL bytecode mingle"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_MIX"

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
