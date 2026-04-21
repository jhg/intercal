#!/bin/zsh
# Test runner for intercalc.sh
#
# Flags:
#   --verbose        show compile/runtime stderr on failure
#   --filter <glob>  only run tests whose name matches the glob
#   --keep           preserve failure artifacts in /tmp/intercal_failures/
setopt NO_ERR_EXIT
setopt PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
COMPILER="${SCRIPT_DIR}/../src/bootstrap/intercalc.sh"
PASS=0
FAIL=0

VERBOSE=0
FILTER=""
KEEP=0
FAILURE_DIR="/tmp/intercal_failures"

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

preserve_failure() {
  local name=$1 source=$2 errfile=$3
  (( KEEP )) || return 0
  local dir="$FAILURE_DIR/$name"
  mkdir -p "$dir"
  cp "$source" "$dir/source.i" 2>/dev/null || true
  cp "$errfile" "$dir/stderr.log" 2>/dev/null || true
}

show_err() {
  local errfile=$1
  (( VERBOSE )) || return 0
  echo "--- stderr ---" >&2
  cat "$errfile" >&2
  echo "--- end stderr ---" >&2
}

run_test() {
  local name=$1 input=$2 expected=$3 stdin_data=${4:-}
  should_run "$name" || return 0
  local binary=$(mktemp /tmp/intercal_test.XXXXXX)

  local errfile=$(mktemp /tmp/intercal_cerr.XXXXXX)
  if ! zsh "$COMPILER" < "$input" > "$binary" 2>"$errfile"; then
    echo "FAIL $name (compile error)"
    head -3 "$errfile" >&2
    show_err "$errfile"
    preserve_failure "$name" "$input" "$errfile"
    FAIL=$((FAIL + 1))
    rm -f "$binary" "$errfile"
    return
  fi
  rm -f "$errfile"
  chmod +x "$binary"

  local actual
  if [[ -n "$stdin_data" ]]; then
    actual=$(echo "$stdin_data" | "$binary" 2>/dev/null) || true
  else
    actual=$("$binary" 2>/dev/null) || true
  fi

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name"
    echo "  expected: [$(echo -n "$expected" | cat -v)]"
    echo "  actual:   [$(echo -n "$actual" | cat -v)]"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$binary"
}

run_test_error() {
  local name=$1 input=$2 expected_code=$3
  should_run "$name" || return 0
  local binary=$(mktemp /tmp/intercal_test.XXXXXX)
  local errfile=$(mktemp /tmp/intercal_err.XXXXXX)
  zsh "$COMPILER" < "$input" > "$binary" 2>"$errfile"
  local exit_code=$?
  local err=$(cat "$errfile")

  if [[ $exit_code -ne 0 ]] && echo "$err" | grep -q "ICL${expected_code}I"; then
    echo "PASS $name (expected error $expected_code)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name (expected error $expected_code)"
    echo "  exit=$exit_code err=[$err]"
    preserve_failure "$name" "$input" "$errfile"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$errfile" "$binary"
}

run_test_runtime_error() {
  local name=$1 input=$2 expected_code=$3
  should_run "$name" || return 0
  local binary=$(mktemp /tmp/intercal_test.XXXXXX)

  if ! zsh "$COMPILER" < "$input" > "$binary" 2>/dev/null; then
    echo "FAIL $name (unexpected compile error)"
    FAIL=$((FAIL + 1))
    rm -f "$binary"
    return
  fi
  chmod +x "$binary"

  local errfile=$(mktemp /tmp/intercal_err.XXXXXX)
  "$binary" > /dev/null 2>"$errfile"
  local exit_code=$?
  local err=$(cat "$errfile")
  rm -f "$errfile"

  if [[ $exit_code -ne 0 ]] && echo "$err" | grep -q "ICL${expected_code}I"; then
    echo "PASS $name (runtime error $expected_code)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name (expected runtime error $expected_code)"
    echo "  exit=$exit_code err=[$err]"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$binary"
}

run_test_with_args() {
  local name=$1 input=$2 expected=$3
  shift 3
  should_run "$name" || return 0
  local args=("$@")
  local binary=$(mktemp /tmp/intercal_test.XXXXXX)

  if ! zsh "$COMPILER" < "$input" > "$binary" 2>/dev/null; then
    echo "FAIL $name (compile error)"
    FAIL=$((FAIL + 1))
    rm -f "$binary"
    return
  fi
  chmod +x "$binary"

  local actual
  actual=$("$binary" "${args[@]}" 2>/dev/null) || true

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name"
    echo "  expected: [$(echo -n "$expected" | head -c 100 | cat -v)]"
    echo "  actual:   [$(echo -n "$actual" | head -c 100 | cat -v)]"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$binary"
}

cd "$SCRIPT_DIR"

echo "Running INTERCAL compiler tests..."
echo ""

# Positive tests
run_test "give_up" test_give_up.i ""
run_test "read_out_5" test_read_out_num.i "V"
run_test "variables" test_variables.i "XLII"
run_test "hello_world" test_hello.i "$(printf 'Hello, World!\n')"
run_test "control_flow" test_control.i "VII"
run_test "syslib_add" test_syslib.i "VIII"
run_test "syslib_multiply" test_multiply.i "XLII"
run_test "syslib_divide" test_divide.i "VII"
run_test "stash_retrieve" test_stash.i "VII"
run_test "abstain" test_abstain.i "V"

run_test "come_from" test_come_from.i "XCIX"
run_test "multidim_array" test_multidim_array.i "XLII"
run_test "forget" test_forget.i "XLII"
run_test "ignore_remember" test_ignore_remember.i "XLII"
run_test "nested_expr" test_nested_expr.i "III"
run_test "read_out_multi" test_read_out_multi.i "$(printf 'V\nXLII')"
run_test "abstain_gerund" test_abstain_gerund.i "XLII"
run_test "write_in" test_write_in.i "CXXIII" "ONE TWO THREE"
run_test "overbar" test_overbar.i "_IVDLXVII"

# Label 666 syscall tests
run_test_with_args "syscall_readself" test_syscall_readself.i "$(cat test_syscall_readself.i)" "$SCRIPT_DIR/test_syscall_readself.i"

# Compile-time error tests
run_test_error "politeness_rude" test_errors_rude.i "079"
run_test_error "politeness_polite" test_errors_polite.i "099"

# Runtime error tests
run_test_runtime_error "error_e123" test_error_e123.i "123"
run_test_runtime_error "error_e621" test_error_e621.i "621"
run_test_runtime_error "error_e633" test_error_e633.i "633"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
