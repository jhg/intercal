#!/bin/zsh
# Tests for the evolving self-hosted compiler (stage3.i).
#
# Each test compiles stage3.i via bootstrap, runs the resulting binary
# with a source input, and checks stdout matches expected output.
#
# Flags:
#   --verbose   show full stderr on failures
#   --filter <glob>   only run matching tests
#   --keep      preserve /tmp/intercal_stage3_failures/<test>/
setopt NO_ERR_EXIT
setopt PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
STAGE3_SRC="${ROOT_DIR}/src/compiler/stage3.i"
FAILURE_DIR="/tmp/intercal_stage3_failures"

VERBOSE=0
FILTER=""
KEEP=0

while (( $# > 0 )); do
  case "$1" in
    --verbose) VERBOSE=1 ;;
    --keep) KEEP=1 ;;
    --filter) FILTER="$2"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

if (( KEEP )); then
  rm -rf "$FAILURE_DIR"
  mkdir -p "$FAILURE_DIR"
fi

should_run() {
  [[ -z "$FILTER" ]] && return 0
  [[ "$1" == ${~FILTER} ]]
}

STAGE3_BIN="${ROOT_DIR}/stage3_bin"
if [[ ! -f "$STAGE3_BIN" || "$STAGE3_SRC" -nt "$STAGE3_BIN" ]]; then
  echo "Building stage3 compiler via bootstrap..." >&2
  zsh "$COMPILER" < "$STAGE3_SRC" > "$STAGE3_BIN" 2>/tmp/stage3_build_err || {
    echo "FAILED to build stage3_bin:" >&2
    cat /tmp/stage3_build_err >&2
    exit 1
  }
  chmod +x "$STAGE3_BIN"
fi

PASS=0
FAIL=0

run_stage3() {
  local name=$1 input_file=$2 expected=$3
  should_run "$name" || return 0

  local actual errfile=$(mktemp /tmp/stage3_err.XXXXXX)
  actual=$("$STAGE3_BIN" "$input_file" 2>"$errfile") || {
    local rc=$?
    echo "FAIL $name (stage3 exit $rc)"
    (( VERBOSE )) && cat "$errfile" >&2
    if (( KEEP )); then
      local dir="$FAILURE_DIR/$name"
      mkdir -p "$dir"
      cp "$input_file" "$dir/input"
      cp "$errfile" "$dir/stderr"
    fi
    rm -f "$errfile"
    FAIL=$((FAIL + 1))
    return
  }
  rm -f "$errfile"

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name (output mismatch)"
    echo "  expected: [$expected]"
    echo "  actual:   [$actual]"
    FAIL=$((FAIL + 1))
  fi
}

cd "$SCRIPT_DIR"

echo "Running Stage 3 (self-hosted compiler under development) tests..."
echo ""

# Stage 3.1.a: byte count test
# Create fixtures on the fly so tests are self-contained.
FIXTURES=$(mktemp -d /tmp/stage3_fix.XXXXXX)
printf '' > "$FIXTURES/empty.i"
printf 'A' > "$FIXTURES/one.i"
printf 'ABC' > "$FIXTURES/three.i"
printf 'DO GIVE UP\n' > "$FIXTURES/give_up.i"

# Stage 3.1.a byte count
# Stage 3.1.b first byte value as Roman after the count
# Stage 3.1.c last byte value as Roman after the first
# Format: <count roman><newline><first byte roman><newline><last byte roman>
run_stage3 "one_byte_A"   "$FIXTURES/one.i"     "$(printf 'I\nLXV\nLXV')"
run_stage3 "three_bytes"  "$FIXTURES/three.i"   "$(printf 'III\nLXV\nLXVII')"
run_stage3 "give_up_11b"  "$FIXTURES/give_up.i" "$(printf 'XI\nLXVIII\nX')"

rm -rf "$FIXTURES"

echo ""
echo "Stage 3 results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
