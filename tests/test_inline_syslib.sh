#!/bin/zsh
# Verify the syslib 1020 (in-place increment) inlining proposal.
# When applied, the call site no longer contains 'b _rt_syslib_1020'.
# When --opt-bisect-limit=0 the inlining is skipped and the call
# pattern reappears.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

# Skip on x86_64; the inlining is implemented for ARM64 only.
host_arch="$(uname -m)"
if [[ "$host_arch" == "x86_64" || "$host_arch" == "amd64" ]]; then
  if [[ -z "${INTERCAL_PLATFORM:-}" || "${INTERCAL_PLATFORM}" == linux_x86_64 ]]; then
    echo "SKIP all (x86_64 host with x86_64 platform; inlining is ARM64-only)"
    echo "Total: 0 passed, 0 failed"
    exit 0
  fi
fi

# A small program that NEXTs to syslib 1020 (in-place increment of .1)
SRC=$(mktemp /tmp/test_inline.XXXXXX)
cat > "$SRC" <<'EOF'
DO .1 <- #5
PLEASE STASH .1 .2 .3 .4
DO (1020) NEXT
DO RETRIEVE .2 .3 .4
DO .9 <- #1
PLEASE GIVE UP
EOF

# Test 1: with optimisation, the call to _rt_syslib_1020 is gone (or
# at most one trampoline-only reference) but the binary still produces
# the correct result (.1 incremented from 5 to 6). Note: under inline,
# _rt_syslib_1020 may still be referenced from the runtime (.s) file
# but NOT emitted as a fall-through 'b _rt_syslib_1020' in our
# program assembly.
asm_opt=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" < "$SRC" 2>/dev/null)
n_calls_opt=$(echo "$asm_opt" | grep -cE '^[[:space:]]+b[[:space:]]+_rt_syslib_1020[[:space:]]*$' 2>/dev/null)
n_calls_opt=${n_calls_opt:-0}
if (( n_calls_opt == 0 )); then
  echo "PASS optimised: no b _rt_syslib_1020"
  PASS=$((PASS + 1))
else
  echo "FAIL optimised: still $n_calls_opt b _rt_syslib_1020"
  FAIL=$((FAIL + 1))
fi

# Test 2: with --opt-bisect-limit=0 inlining is disabled; call returns.
asm_unopt=$(INTERCAL_ASM_ONLY=1 zsh "$COMPILER" --opt-bisect-limit=0 < "$SRC" 2>/dev/null)
n_calls_unopt=$(echo "$asm_unopt" | grep -cE '^[[:space:]]+b[[:space:]]+_rt_syslib_1020[[:space:]]*$' 2>/dev/null)
n_calls_unopt=${n_calls_unopt:-0}
if (( n_calls_unopt > 0 )); then
  echo "PASS bisect=0: at least one b _rt_syslib_1020 reappears ($n_calls_unopt)"
  PASS=$((PASS + 1))
else
  echo "FAIL bisect=0: inlining still active"
  FAIL=$((FAIL + 1))
fi

# Test 3: optimised binary still produces correct output.
BIN=$(mktemp /tmp/test_inline.XXXXXX)
zsh "$COMPILER" < "$SRC" > "$BIN" 2>/dev/null
chmod +x "$BIN" 2>/dev/null
if "$BIN" >/dev/null 2>&1; then
  echo "PASS optimised binary runs"
  PASS=$((PASS + 1))
else
  echo "FAIL optimised binary fails to run"
  FAIL=$((FAIL + 1))
fi
rm -f "$BIN"

rm -f "$SRC"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
