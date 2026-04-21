#!/bin/zsh
# bench.sh - measure compile and link timings across the toolchain.
#
# Usage:
#   tools/bench.sh                       # run all benchmarks, print table
#   tools/bench.sh --json                # emit JSON per benchmark
#   tools/bench.sh --compare baseline.json  # diff against a saved baseline
#
# Benchmarks:
#   bootstrap_simple    : compile tests/test_give_up.i with intercalc.sh
#   bootstrap_hello     : compile tests/test_hello.i
#   bootstrap_suite     : time to run the full 25-test suite
#   intercal_core_build : bootstrap compiles compiler.i
#   stage3_build        : bootstrap compiles stage3.i
#   self_suite          : time to run the full 25-test self-hosted suite
#   stage3_suite        : time to run the 3 stage3 tests
#   syslib_pure_add     : compile tests/test_syslib.i with --pure-syslib
set -euo pipefail

ROOT_DIR="${0:A:h}/.."
MODE="table"
BASELINE=""
while (( $# > 0 )); do
  case "$1" in
    --json) MODE="json" ;;
    --compare) MODE="compare"; BASELINE="$2"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

cd "$ROOT_DIR"

# Portable millisecond timer. BSD date on macOS lacks %N, so use python as fallback.
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo python3)
now_ms() {
  "$PY" -c 'import time; print(int(time.time()*1000))'
}

bench() {
  local name="$1"
  shift
  local start=$(now_ms)
  "$@" >/dev/null 2>&1 || { echo "$name FAILED" >&2; return 1; }
  local end=$(now_ms)
  echo $((end - start))
}

RESULTS=()

b1=$(bench bootstrap_simple \
  sh -c 'tmp=$(mktemp); zsh src/bootstrap/intercalc.sh < tests/test_give_up.i > "$tmp"; rm -f "$tmp"')
RESULTS+=("bootstrap_simple:$b1")

b2=$(bench bootstrap_hello \
  sh -c 'tmp=$(mktemp); zsh src/bootstrap/intercalc.sh < tests/test_hello.i > "$tmp"; rm -f "$tmp"')
RESULTS+=("bootstrap_hello:$b2")

b3=$(bench bootstrap_suite zsh tests/run_tests.sh)
RESULTS+=("bootstrap_suite:$b3")

b4=$(bench intercal_core_build \
  sh -c 'tmp=$(mktemp); zsh src/bootstrap/intercalc.sh < src/compiler/compiler.i > "$tmp"; rm -f "$tmp"')
RESULTS+=("intercal_core_build:$b4")

b5=$(bench stage3_build \
  sh -c 'tmp=$(mktemp); zsh src/bootstrap/intercalc.sh < src/compiler/stage3.i > "$tmp"; rm -f "$tmp"')
RESULTS+=("stage3_build:$b5")

rm -f intercal_core stage3_bin
b6=$(bench self_suite zsh tests/run_self_tests.sh)
RESULTS+=("self_suite:$b6")

b7=$(bench stage3_suite zsh tests/run_stage3_tests.sh)
RESULTS+=("stage3_suite:$b7")

b8=$(bench syslib_pure_add \
  sh -c 'tmp=$(mktemp); zsh src/bootstrap/intercalc.sh --pure-syslib < tests/test_syslib.i > "$tmp"; rm -f "$tmp"')
RESULTS+=("syslib_pure_add:$b8")

case "$MODE" in
  table)
    printf "%-24s %10s\n" benchmark "time(ms)"
    printf "%-24s %10s\n" ------------------------ ----------
    for r in $RESULTS; do
      name="${r%%:*}"
      ms="${r##*:}"
      printf "%-24s %10s\n" "$name" "$ms"
    done
    ;;
  json)
    printf "{"
    first=1
    for r in $RESULTS; do
      name="${r%%:*}"
      ms="${r##*:}"
      (( first )) || printf ","
      first=0
      printf "\"%s\":%s" "$name" "$ms"
    done
    printf "}\n"
    ;;
  compare)
    if [[ ! -f "$BASELINE" ]]; then
      echo "baseline not found: $BASELINE" >&2
      exit 1
    fi
    printf "%-24s %10s %10s %8s\n" benchmark current baseline "delta"
    printf "%-24s %10s %10s %8s\n" ------------------------ ---------- ---------- --------
    for r in $RESULTS; do
      name="${r%%:*}"
      ms="${r##*:}"
      base=$(python3 -c "import json,sys; d=json.load(open('$BASELINE')); print(d.get('$name','?'))")
      if [[ "$base" != "?" ]]; then
        delta=$((ms - base))
        pct=$(( delta * 100 / (base > 0 ? base : 1) ))
        printf "%-24s %10s %10s %+7s%%\n" "$name" "$ms" "$base" "$pct"
      else
        printf "%-24s %10s %10s %8s\n" "$name" "$ms" "?" "n/a"
      fi
    done
    ;;
esac
