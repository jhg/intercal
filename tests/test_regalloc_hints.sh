#!/bin/zsh
# Verify INTERCAL_REGALLOC_HINTS=1 populates assembly with regalloc
# decision comments AND does not change runtime behaviour.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

# Stub cc that writes assembly to a known path instead of compiling.
STUB_DIR=$(mktemp -d /tmp/test_regalloc_hints.XXXXXX)
cat > "$STUB_DIR/cc" <<'EOF'
#!/bin/zsh
# Capture stdin to /tmp/asm_capture.s; emit a one-byte placeholder
# so the harness's chmod +x and trap-cleanup do not error.
cat > "$ASM_CAPTURE_PATH"
# Consume any additional flags but ignore them; emit a tiny shell
# placeholder so the wrapper's `chmod +x` succeeds.
typeset -i out_idx=-1
typeset i=1
for arg in "$@"; do
  if [[ "$arg" == "-o" ]]; then
    out_idx=$((i + 1))
  fi
  i=$((i + 1))
done
if (( out_idx > 0 )); then
  out_path="${@[$out_idx]}"
  printf '#!/bin/sh\nexit 0\n' > "$out_path"
fi
EOF
chmod +x "$STUB_DIR/cc"

ASM_CAPTURE_PATH=$(mktemp /tmp/asm_capture.XXXXXX.s)
export ASM_CAPTURE_PATH

SRC=$(mktemp /tmp/test_regalloc_hints_src.XXXXXX)
cat > "$SRC" <<'EOF'
DO .1 <- #5
PLEASE DO .2 <- #7
DO .3 <- #11
PLEASE DO .4 <- #13
DO .5 <- #17
DO .6 <- #19
DO READ OUT .1
DO READ OUT .2
DO READ OUT .3
DO GIVE UP
EOF

# Compile with the stub cc so we can inspect the assembly directly.
INTERCAL_CC="$STUB_DIR/cc" \
INTERCAL_REGALLOC_HINTS=1 \
zsh "$COMPILER" < "$SRC" > /dev/null 2>/dev/null
rc=$?

if grep -q '// regalloc: spot_1 -> R0' "$ASM_CAPTURE_PATH"; then
  echo "PASS regalloc hint for spot_1 -> R0 present"
  PASS=$((PASS + 1))
else
  echo "FAIL spot_1 hint missing"
  FAIL=$((FAIL + 1))
fi

if grep -q '// regalloc: spot_5 spilled\|// regalloc: spot_5 -> R' "$ASM_CAPTURE_PATH"; then
  echo "PASS regalloc decision present for spot_5"
  PASS=$((PASS + 1))
else
  echo "FAIL spot_5 decision missing"
  FAIL=$((FAIL + 1))
fi

# Behaviour test: with hints flag on, output of a real binary still matches expected.
ACTUAL=$(zsh "$COMPILER" < "$SRC" 2>/dev/null)
chmod +x /dev/stdin 2>/dev/null
BIN=$(mktemp /tmp/test_regalloc_hints_bin.XXXXXX)
INTERCAL_REGALLOC_HINTS=1 zsh "$COMPILER" < "$SRC" > "$BIN" 2>/dev/null
chmod +x "$BIN"
out=$("$BIN")
rc_out=$?
rm -f "$BIN"

EXPECTED=$'V\nVII\nXI'
if [[ "$out" == "$EXPECTED" ]] && (( rc_out == 0 )); then
  echo "PASS hint flag does not regress runtime behaviour"
  PASS=$((PASS + 1))
else
  echo "FAIL runtime regression: out=[$out] rc=$rc_out"
  FAIL=$((FAIL + 1))
fi

rm -rf "$STUB_DIR" "$ASM_CAPTURE_PATH" "$SRC"

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
