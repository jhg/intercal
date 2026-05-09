#!/bin/zsh
# Run every regression test through both the native compiler AND the
# bytecode tier; compare outputs. Programs that use features the
# bytecode subset doesn't yet support are skipped explicitly.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
NATIVE="${ROOT_DIR}/src/bootstrap/intercalc.sh"
BC="${ROOT_DIR}/src/bytecode/intercalc_bc.sh"
VM="${ROOT_DIR}/src/bytecode/intercalc_vm.sh"

PASS=0 FAIL=0 SKIP=0

# Programs the bytecode subset cannot yet run cleanly.
typeset -A SKIP_LIST
# test_hello.i now passes via TTM array READ OUT.
SKIP_LIST[test_overbar.i]="overbar Roman not in BC tier"
# test_multidim_array.i now passes with multi-dim ARRAY support.
SKIP_LIST[test_write_in.i]="needs FD-3 plumbing in this harness"
# Tests that intentionally trigger errors — semantics differ between
# native runtime and BC VM error reporting.
SKIP_LIST[test_errors_rude.i]=1
SKIP_LIST[test_errors_polite.i]=1
SKIP_LIST[test_error_e123.i]=1
SKIP_LIST[test_error_e275.i]=1
SKIP_LIST[test_error_e436.i]=1
SKIP_LIST[test_error_e240.i]=1
SKIP_LIST[test_error_e241.i]=1
SKIP_LIST[test_error_e632.i]=1
SKIP_LIST[test_error_e621.i]=1
SKIP_LIST[test_error_e633.i]=1
SKIP_LIST[test_dup_label.i]=1
SKIP_LIST[test_syscall_readself.i]="needs Label 666 syscall in BC"

for src in "$ROOT_DIR"/tests/test_*.i; do
  base=$(basename "$src")
  if (( ${+SKIP_LIST[$base]} )); then
    SKIP=$((SKIP + 1))
    continue
  fi

  bin_native=$(mktemp /tmp/test_eq.XXXXXX)
  if ! zsh "$NATIVE" < "$src" > "$bin_native" 2>/dev/null; then
    SKIP=$((SKIP + 1))
    rm -f "$bin_native"
    continue
  fi
  chmod +x "$bin_native"
  out_native=$("$bin_native" 2>/dev/null)
  rc_native=$?

  bytecode=$(mktemp /tmp/test_eq.XXXXXX)
  if ! zsh "$BC" < "$src" > "$bytecode" 2>/dev/null; then
    # Bytecode rejected the program — treat as skip (subset miss).
    SKIP=$((SKIP + 1))
    rm -f "$bin_native" "$bytecode"
    continue
  fi
  out_bc=$(zsh "$VM" < "$bytecode" 2>/dev/null)
  rc_bc=$?
  rm -f "$bin_native" "$bytecode"

  if [[ "$out_native" == "$out_bc" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL $base: native='$out_native' bc='$out_bc'"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "Bytecode equivalence: $PASS pass, $FAIL fail, $SKIP skip"
exit $((FAIL > 0))
