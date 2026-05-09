#!/bin/zsh
# Verify --emit-help lists every flag the parser accepts and every
# INTERCAL_* env var the codebase reads.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

OUT=$(zsh "$COMPILER" --emit-help 2>&1)

# Test 1: header is present.
if [[ "$OUT" == *"intercalc.sh — INTERCAL bootstrap compiler"* ]]; then
  echo "PASS header present"
  PASS=$((PASS + 1))
else
  echo "FAIL header missing"
  FAIL=$((FAIL + 1))
fi

# Test 2: every --emit-* flag is documented.
for flag in --emit-cfg --emit-3addr --emit-tokens --emit-ir-full \
            --emit-ssa --emit-sccp --emit-sccp-wz --emit-regalloc \
            --emit-effects --emit-ir-real --emit-opt-summary \
            --emit-help; do
  if [[ "$OUT" == *"$flag"* ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL flag $flag not in --emit-help output"
    FAIL=$((FAIL + 1))
  fi
done

# Test 3: every INTERCAL_* env var is documented.
for var in INTERCAL_NEW_IR INTERCAL_REGALLOC_HINTS INTERCAL_SCCP_WZ_FEED \
           INTERCAL_PLATFORM INTERCAL_HOME INTERCAL_SYSLIB \
           INTERCAL_REPRODUCIBLE INTERCAL_ASM_ONLY INTERCAL_CC; do
  if [[ "$OUT" == *"$var"* ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL env var $var not in --emit-help output"
    FAIL=$((FAIL + 1))
  fi
done

# Test 4: bytecode tier mentioned.
if [[ "$OUT" == *"intercalc_bc.sh"* ]] && [[ "$OUT" == *"BC_TRACE"* ]]; then
  echo "PASS bytecode tier mentioned"
  PASS=$((PASS + 1))
else
  echo "FAIL bytecode tier missing"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
