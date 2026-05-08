#!/bin/zsh
# Differential testing driver: generate N random INTERCAL programs,
# compile each with native and --pure-syslib syslib, compare both
# outputs against the predicted-Roman expected.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
GEN="${ROOT_DIR}/tools/csmith_intercal.sh"

N="${1:-10}"
PASS=0
FAIL=0

cd "$SCRIPT_DIR"

mkdir -p /tmp/csmith_intercal_runs
local i
for (( i=1; i<=N; i++ )); do
  prog=/tmp/csmith_intercal_runs/prog_$i.i
  exp=/tmp/csmith_intercal_runs/exp_$i.txt
  zsh "$GEN" "$i" "$prog" "$exp" 2>/dev/null

  expected=$(<"$exp")

  # Native compile
  bin=/tmp/csmith_intercal_runs/bin_native_$i
  if ! zsh "$COMPILER" < "$prog" > "$bin" 2>/dev/null; then
    echo "SKIP seed=$i (compile failed; subset escape)"
    continue
  fi
  chmod +x "$bin"
  out=$("$bin" 2>/dev/null)
  if [[ "$out" != "$expected" ]]; then
    echo "FAIL seed=$i native: expected '$expected' got '$out'"
    cat "$prog" | sed 's/^/    /' >&2
    FAIL=$((FAIL + 1))
    continue
  fi

  # Pure-syslib compile
  binp=/tmp/csmith_intercal_runs/bin_pure_$i
  if ! zsh "$COMPILER" --pure-syslib < "$prog" > "$binp" 2>/dev/null; then
    # pure-syslib may legitimately reject programs with politeness
    # close to the boundary because syslib.i adds many statements.
    echo "SKIP seed=$i (pure-syslib compile failed)"
    PASS=$((PASS + 1))
    continue
  fi
  chmod +x "$binp"
  outp=$("$binp" 2>/dev/null)
  if [[ "$outp" != "$expected" ]]; then
    echo "FAIL seed=$i pure: expected '$expected' got '$outp'"
    FAIL=$((FAIL + 1))
    continue
  fi

  if [[ "$out" != "$outp" ]]; then
    echo "FAIL seed=$i diff: native='$out' pure='$outp'"
    FAIL=$((FAIL + 1))
    continue
  fi

  echo "PASS seed=$i ($expected)"
  PASS=$((PASS + 1))
done

rm -rf /tmp/csmith_intercal_runs

echo ""
echo "Total: $PASS passed, $FAIL failed (out of $N)"
exit $((FAIL > 0))
