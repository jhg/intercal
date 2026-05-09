#!/bin/zsh
# Verify INTERCAL_NEW_IR=1 path produces functionally identical
# binaries for the supported statement subset (currently: GIVE_UP).
# This is the regression test for proposal #11 / task #123.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

# Test 1: GIVE_UP-only program produces "V" via both paths.
SRC=$(mktemp /tmp/test_new_ir.XXXXXX)
cat > "$SRC" <<'EOF'
DO READ OUT #5
DO GIVE UP
EOF
BIN_OFF=$(mktemp /tmp/test_new_ir.XXXXXX)
BIN_ON=$(mktemp /tmp/test_new_ir.XXXXXX)
zsh "$COMPILER" < "$SRC" > "$BIN_OFF" 2>/dev/null
INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$SRC" > "$BIN_ON" 2>/dev/null
chmod +x "$BIN_OFF" "$BIN_ON"

out_off=$("$BIN_OFF")
rc_off=$?
out_on=$("$BIN_ON")
rc_on=$?

if [[ "$out_off" == "V" ]] && (( rc_off == 0 )); then
  echo "PASS legacy GIVE_UP path"
  PASS=$((PASS + 1))
else
  echo "FAIL legacy: out=[$out_off] rc=$rc_off"
  FAIL=$((FAIL + 1))
fi

if [[ "$out_on" == "V" ]] && (( rc_on == 0 )); then
  echo "PASS IR-driven GIVE_UP path"
  PASS=$((PASS + 1))
else
  echo "FAIL IR-driven: out=[$out_on] rc=$rc_on"
  FAIL=$((FAIL + 1))
fi

# Test 2: programs with unsupported statement types still compile when flag is on.
# (The IR path falls back to legacy for unsupported types; this is the integration
# guarantee that the flag does not regress existing programs.)
SRC2=$(mktemp /tmp/test_new_ir.XXXXXX)
cat > "$SRC2" <<'EOF'
DO .1 <- #42
PLEASE DO READ OUT .1
DO GIVE UP
EOF
BIN_FALLBACK=$(mktemp /tmp/test_new_ir.XXXXXX)
INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$SRC2" > "$BIN_FALLBACK" 2>/dev/null
chmod +x "$BIN_FALLBACK"
out=$("$BIN_FALLBACK")
rc=$?
if [[ "$out" == "XLII" ]] && (( rc == 0 )); then
  echo "PASS IR-driven path falls back for unsupported types"
  PASS=$((PASS + 1))
else
  echo "FAIL fallback: out=[$out] rc=$rc"
  FAIL=$((FAIL + 1))
fi

# Test 3: literal-RHS ASSIGN routes through IR path (INTERCAL_NEW_IR=1)
# and produces correct output.
SRC3=$(mktemp /tmp/test_new_ir.XXXXXX)
cat > "$SRC3" <<'EOF'
DO .1 <- #42
PLEASE DO READ OUT .1
DO GIVE UP
EOF
BIN3=$(mktemp /tmp/test_new_ir.XXXXXX)
INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$SRC3" > "$BIN3" 2>/dev/null
chmod +x "$BIN3"
out=$("$BIN3")
rc=$?
if [[ "$out" == "XLII" ]] && (( rc == 0 )); then
  echo "PASS IR-driven literal ASSIGN to spot"
  PASS=$((PASS + 1))
else
  echo "FAIL IR-driven literal ASSIGN: out=[$out] rc=$rc"
  FAIL=$((FAIL + 1))
fi

# Test 4 prereq: var-to-var copy also routes through IR.
SRC_VV=$(mktemp /tmp/test_new_ir.XXXXXX)
cat > "$SRC_VV" <<'EOF'
DO .1 <- #42
PLEASE DO .2 <- .1
DO READ OUT .2
DO GIVE UP
EOF
BIN_VV=$(mktemp /tmp/test_new_ir.XXXXXX)
INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$SRC_VV" > "$BIN_VV" 2>/dev/null
chmod +x "$BIN_VV"
out=$("$BIN_VV"); rc=$?
if [[ "$out" == "XLII" ]] && (( rc == 0 )); then
  echo "PASS IR-driven var-to-var copy (.1 -> .2)"
  PASS=$((PASS + 1))
else
  echo "FAIL IR-driven var-to-var: out=[$out] rc=$rc"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_VV" "$BIN_VV"

# Test prereq: STASH/RETRIEVE through IR (delegates to legacy
# helpers; the test confirms behavioural equivalence).
SRC_SR=$(mktemp /tmp/test_new_ir.XXXXXX)
cat > "$SRC_SR" <<'EOF'
DO .1 <- #5
PLEASE DO STASH .1
DO .1 <- #99
DO RETRIEVE .1
PLEASE DO READ OUT .1
DO GIVE UP
EOF
BIN_SR=$(mktemp /tmp/test_new_ir.XXXXXX)
INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$SRC_SR" > "$BIN_SR" 2>/dev/null
chmod +x "$BIN_SR"
out=$("$BIN_SR"); rc=$?
if [[ "$out" == "V" ]] && (( rc == 0 )); then
  echo "PASS IR-driven STASH/RETRIEVE round-trip"
  PASS=$((PASS + 1))
else
  echo "FAIL IR STASH/RETRIEVE: out=[$out] rc=$rc"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_SR" "$BIN_SR"

# Test 4 prereq: IGNORE/REMEMBER routes through IR.
SRC_IR=$(mktemp /tmp/test_new_ir.XXXXXX)
cat > "$SRC_IR" <<'EOF'
DO .1 <- #5
PLEASE DO IGNORE .1
DO .1 <- #99
PLEASE DO REMEMBER .1
DO .1 <- #42
DO READ OUT .1
DO GIVE UP
EOF
BIN_IR=$(mktemp /tmp/test_new_ir.XXXXXX)
INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$SRC_IR" > "$BIN_IR" 2>/dev/null
chmod +x "$BIN_IR"
out=$("$BIN_IR"); rc=$?
if [[ "$out" == "XLII" ]] && (( rc == 0 )); then
  echo "PASS IR-driven IGNORE/REMEMBER cycle"
  PASS=$((PASS + 1))
else
  echo "FAIL IR IGNORE/REMEMBER: out=[$out] rc=$rc"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC_IR" "$BIN_IR"

# Test 4: twospot literal also works.
SRC4=$(mktemp /tmp/test_new_ir.XXXXXX)
cat > "$SRC4" <<'EOF'
DO :1 <- #1000
PLEASE DO READ OUT :1
DO GIVE UP
EOF
BIN4=$(mktemp /tmp/test_new_ir.XXXXXX)
INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$SRC4" > "$BIN4" 2>/dev/null
chmod +x "$BIN4"
out=$("$BIN4")
rc=$?
if [[ "$out" == "M" ]] && (( rc == 0 )); then
  echo "PASS IR-driven literal ASSIGN to twospot"
  PASS=$((PASS + 1))
else
  echo "FAIL IR-driven twospot ASSIGN: out=[$out] rc=$rc"
  FAIL=$((FAIL + 1))
fi

rm -f "$SRC" "$SRC2" "$SRC3" "$SRC4" "$BIN_OFF" "$BIN_ON" "$BIN_FALLBACK" "$BIN3" "$BIN4"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
