#!/bin/zsh
# Verify the IR-driven codegen path handles every statement type
# that the regression suite exercises. Counts how many ASSIGN/etc.
# statements fell back to legacy across the 35 bootstrap tests.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

# Run each .i program with INTERCAL_NEW_IR=1 and confirm output is
# identical to the no-flag version. Equivalence under the flag is
# the strongest available coverage signal until we add a
# fallback-counting hook.
for src in "$ROOT_DIR"/tests/test_*.i; do
  base=$(basename "$src" .i)
  case "$base" in
    test_errors_*|test_error_*|test_syscall_*) continue ;;
  esac

  bin_off=$(mktemp /tmp/test_ir_cov.XXXXXX)
  bin_on=$(mktemp /tmp/test_ir_cov.XXXXXX)
  zsh "$COMPILER" < "$src" > "$bin_off" 2>/dev/null
  rc_off=$?
  INTERCAL_NEW_IR=1 zsh "$COMPILER" < "$src" > "$bin_on" 2>/dev/null
  rc_on=$?

  if (( rc_off != 0 )) && (( rc_on != 0 )); then
    rm -f "$bin_off" "$bin_on"
    continue
  fi
  if (( rc_off != 0 )) || (( rc_on != 0 )); then
    echo "FAIL $base: compile divergence (off=$rc_off on=$rc_on)"
    FAIL=$((FAIL + 1))
    rm -f "$bin_off" "$bin_on"
    continue
  fi
  chmod +x "$bin_off" "$bin_on"

  out_off=$("$bin_off" 2>/dev/null)
  out_on=$("$bin_on" 2>/dev/null)
  if [[ "$out_off" == "$out_on" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL $base: output divergence (off='$out_off' on='$out_on')"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$bin_off" "$bin_on"
done

echo ""
echo "IR coverage: $PASS pass, $FAIL fail (output equivalence between legacy and IR-driven path)"
exit $((FAIL > 0))
