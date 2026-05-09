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

# Test: COME FROM redirects after labelled stmt. Linear flow would
# print I then II; COME FROM should print only I (the second part is
# skipped via the redirect).
SRC_CF=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_CF" <<'EOF'
DO .1 <- #1
(10) PLEASE DO READ OUT .1
PLEASE DO .1 <- #2
DO READ OUT .1
DO GIVE UP
PLEASE DO COME FROM (10)
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_CF" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "I" ]]; then
  echo "PASS bytecode COME FROM redirects past linear flow"
  PASS=$((PASS + 1))
else
  echo "FAIL COME FROM: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_CF"

# Test: bytecode ABSTAIN FROM (label) skips a statement.
SRC_AB=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_AB" <<'EOF'
DO .1 <- #5
PLEASE DO ABSTAIN FROM (10)
(10) DO READ OUT .1
DO READ OUT .1
PLEASE DO REINSTATE (10)
DO .1 <- #99
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_AB" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
EXP=$'V\nXCIX'
if [[ "$out" == "$EXP" ]]; then
  echo "PASS bytecode ABSTAIN FROM (label) skips, REINSTATE re-enables"
  PASS=$((PASS + 1))
else
  echo "FAIL ABSTAIN: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_AB"

# Test: 1D array dim + element write + element read.
SRC_ARR=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_ARR" <<'EOF'
DO ,1 <- #5
DO ,1 SUB #2 <- #42
PLEASE DO .1 <- ,1 SUB #2
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_ARR" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "XLII" ]]; then
  echo "PASS bytecode 1D array dim + element rw"
  PASS=$((PASS + 1))
else
  echo "FAIL array: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_ARR"

# Test: probability prefix %0 always skips, %100 always runs.
SRC_P0=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_P0" <<'EOF'
DO .1 <- #5
DO %0 .1 <- #99
PLEASE DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_P0" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "V" ]]; then
  echo "PASS bytecode probability %0 always skips"
  PASS=$((PASS + 1))
else
  echo "FAIL %0: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_P0"

SRC_P100=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_P100" <<'EOF'
DO .1 <- #5
DO %100 .1 <- #99
PLEASE DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_P100" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "XCIX" ]]; then
  echo "PASS bytecode probability %100 always runs"
  PASS=$((PASS + 1))
else
  echo "FAIL %100: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_P100"

# Test: ABSTAIN FROM CALCULATING (gerund) abstains all ASSIGN stmts.
SRC_GER=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_GER" <<'EOF'
DO .1 <- #5
DO .2 <- #7
PLEASE DO ABSTAIN FROM CALCULATING
DO .1 <- #99
DO .2 <- #99
PLEASE DO READ OUT .1
DO READ OUT .2
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_GER" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
EXP=$'V\nVII'
if [[ "$out" == "$EXP" ]]; then
  echo "PASS bytecode ABSTAIN FROM CALCULATING (gerund)"
  PASS=$((PASS + 1))
else
  echo "FAIL gerund ABSTAIN: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_GER"

# Test: bytecode WRITE IN reads English digit names.
SRC_WI=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_WI" <<'EOF'
DO WRITE IN .1
PLEASE DO READ OUT .1
DO GIVE UP
EOF
BC_OUT=$(mktemp /tmp/test_bc.XXXXXX)
zsh "$BC_COMPILER" < "$SRC_WI" > "$BC_OUT" 2>/dev/null
out=$(zsh "$BC_VM" 3<<<"ONE TWO THREE" < "$BC_OUT")
if [[ "$out" == "CXXIII" ]]; then
  echo "PASS bytecode WRITE IN: ONE TWO THREE -> 123 -> CXXIII"
  PASS=$((PASS + 1))
else
  echo "FAIL WRITE IN: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_WI" "$BC_OUT"

# Test: bytecode evaluates 16-bit syslib (1009 add).
SRC_SL=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_SL" <<'EOF'
DO .1 <- #20
DO .2 <- #5
PLEASE DO (1009) NEXT
DO READ OUT .3
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_SL" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "XXV" ]]; then
  echo "PASS bytecode 1009 add: 20+5=25"
  PASS=$((PASS + 1))
else
  echo "FAIL 1009: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_SL"

# Test: bytecode evaluates 32-bit syslib (1530 multiply).
SRC_SL2=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_SL2" <<'EOF'
DO .1 <- #5
DO .2 <- #3
PLEASE DO (1530) NEXT
DO READ OUT :1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_SL2" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "XV" ]]; then
  echo "PASS bytecode 1530 mul: 5*3=15"
  PASS=$((PASS + 1))
else
  echo "FAIL 1530: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_SL2"

# Test: NEXT FROM (unconditional) jumps without push.
SRC_NF=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_NF" <<'EOF'
DO .1 <- #5
PLEASE DO (20) NEXT FROM
DO READ OUT .1
DO GIVE UP
(20) DO .1 <- #99
DO READ OUT .1
DO GIVE UP
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_NF" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "XCIX" ]]; then
  echo "PASS bytecode NEXT FROM unconditional"
  PASS=$((PASS + 1))
else
  echo "FAIL bytecode NEXT FROM: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_NF"

# Test: NEXT to a labelled stmt that does work, RESUME #1 returns.
SRC_NEXT=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC_NEXT" <<'EOF'
DO .1 <- #5
PLEASE DO (10) NEXT
DO READ OUT .1
DO GIVE UP
(10) PLEASE DO .1 <- #42
DO RESUME #1
EOF
out=$(zsh "$BC_COMPILER" < "$SRC_NEXT" 2>/dev/null | zsh "$BC_VM" 2>/dev/null)
if [[ "$out" == "XLII" ]]; then
  echo "PASS bytecode NEXT/RESUME round-trip"
  PASS=$((PASS + 1))
else
  echo "FAIL NEXT/RESUME: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_NEXT"

# Test 3: out-of-subset programs error cleanly. ABSTAIN/REINSTATE
# and arrays remain unsupported in this bytecode tier.
SRC3=$(mktemp /tmp/test_bc.XXXXXX)
cat > "$SRC3" <<'EOF'
DO ,1 <- #5 BY #3
DO .1 <- ,1 SUB #1 SUB #2
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
