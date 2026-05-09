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

rm -f "$SRC" "$SRC2" "$BIN_OFF" "$BIN_ON" "$BIN_FALLBACK"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
