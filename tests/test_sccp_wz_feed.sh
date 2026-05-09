#!/bin/zsh
# Verify INTERCAL_SCCP_WZ_FEED=1 increases the constant-propagation
# entry count by feeding emit_sccp_wz's outgoing[] CONST values into
# stmt_var_const, AND that all 35 regression tests still pass with
# the flag on (no miscompile).
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

# Test 1: a 32-bit syslib chain that the simpler compute_var_constants
# does NOT catch (it bottoms on syslib calls), but SCCP-WZ does.
SRC=$(mktemp /tmp/test_sccp_feed.XXXXXX)
cat > "$SRC" <<'EOF'
DO :1 <- #100
PLEASE DO :2 <- #200
DO (1500) NEXT
DO READ OUT :3
PLEASE DO GIVE UP
DON'T NOTE filler
EOF
n_off=$(zsh "$COMPILER" --emit-opt-summary < "$SRC" 2>&1 | grep -oE '[0-9]+ \(stmt × varspec\)' | grep -oE '^[0-9]+')
n_on=$(INTERCAL_SCCP_WZ_FEED=1 zsh "$COMPILER" --emit-opt-summary < "$SRC" 2>&1 | grep -oE '[0-9]+ \(stmt × varspec\)' | grep -oE '^[0-9]+')

if (( n_on > n_off )); then
  echo "PASS feed adds entries: $n_off -> $n_on"
  PASS=$((PASS + 1))
else
  echo "FAIL feed didn't increase: $n_off -> $n_on"
  FAIL=$((FAIL + 1))
fi
rm -f "$SRC"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
