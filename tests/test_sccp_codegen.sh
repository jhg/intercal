#!/bin/zsh
# Verify SCCP feeds codegen with cross-statement constants. When a
# variable's value is a known constant at the use site, codegen
# substitutes the literal instead of emitting a load.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Test 1: program with cross-stmt constant. .1 = 7, then .2 = .1.
# Optimisation: .2 = #7 directly, no load of _spot_1.
SRC1=$(mktemp /tmp/test_sccpcg.XXXXXX)
cat > "$SRC1" <<'EOF'
DO .1 <- #7
DO .2 <- .1
PLEASE GIVE UP
EOF
asm_opt=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC1" 2>/dev/null)
asm_unopt=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" --opt-bisect-limit=0 < "$SRC1" 2>/dev/null)

# With optimisation, the assembly emitting the second statement
# should NOT contain a load from _spot_1 (the use-site read of .1).
# With bisect=0 it should.
n_load_spot1_opt=$(echo "$asm_opt" | grep -c "ldr.*_spot_1\|adrp.*_spot_1@PAGE" 2>/dev/null)
n_load_spot1_unopt=$(echo "$asm_unopt" | grep -c "ldr.*_spot_1\|adrp.*_spot_1@PAGE" 2>/dev/null)
n_load_spot1_opt=${n_load_spot1_opt:-0}
n_load_spot1_unopt=${n_load_spot1_unopt:-0}
if (( n_load_spot1_opt < n_load_spot1_unopt )); then
  echo "PASS sccp prop reduced loads from _spot_1 ($n_load_spot1_unopt -> $n_load_spot1_opt)"
  PASS=$((PASS + 1))
else
  echo "FAIL sccp prop did not reduce loads from _spot_1"
  echo "  unopt loads: $n_load_spot1_unopt"
  echo "  opt loads:   $n_load_spot1_opt"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC1"

# Test 2: optimised binary still produces correct result.
# Build a program with READ OUT to verify the constant flowed through.
SRC2=$(mktemp /tmp/test_sccpcg.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #5
DO .2 <- .1
DO READ OUT .2
PLEASE GIVE UP
EOF
BIN=$(mktemp /tmp/test_sccpcg.XXXXXX)
zsh "$COMPILER" < "$SRC2" > "$BIN" 2>/dev/null
chmod +x "$BIN" 2>/dev/null
out=$("$BIN" 2>/dev/null)
if [[ "$out" == "V" ]]; then
  echo "PASS optimised binary correct: V"
  PASS=$((PASS + 1))
else
  echo "FAIL optimised binary: got '$out'"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC2" "$BIN"

# Test 3: dynamic input keeps the load.
SRC3=$(mktemp /tmp/test_sccpcg.XXXXXX)
cat > "$SRC3" <<'EOF'
PLEASE WRITE IN .1
DO .2 <- .1
DO .3 <- .1
PLEASE GIVE UP
EOF
asm=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC3" 2>/dev/null)
n_load=$(echo "$asm" | grep -c "ldr.*_spot_1\|adrp.*_spot_1@PAGE" 2>/dev/null)
n_load=${n_load:-0}
if (( n_load >= 1 )); then
  echo "PASS dynamic input keeps _spot_1 loads"
  PASS=$((PASS + 1))
else
  echo "FAIL dynamic input: load was elided unsoundly"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC3"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
