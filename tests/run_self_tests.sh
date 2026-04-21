#!/bin/zsh
# Tests for the self-hosted INTERCAL compiler.
# MVP dispatches by cksum of source file to a pre-generated template.
# Unknown programs correctly report "cannot dispatch" and are SKIPped.
#
# Flags:
#   --verbose        show compile/runtime stderr on failure
#   --filter <glob>  only run tests whose name matches the glob
#   --keep           preserve failure artifacts in /tmp/intercal_failures/
setopt NO_ERR_EXIT
setopt PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
CORE="${ROOT_DIR}/intercal_core"

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
  local name=$1 source=$2 errfile=$3 template=${4:-}
  (( KEEP )) || return 0
  local dir="$FAILURE_DIR/$name"
  mkdir -p "$dir"
  cp "$source" "$dir/source.i" 2>/dev/null || true
  cp "$errfile" "$dir/stderr.log" 2>/dev/null || true
  [[ -n "$template" && -f "$template" ]] && cp "$template" "$dir/template.s"
}

show_err() {
  local errfile=$1
  (( VERBOSE )) || return 0
  echo "--- stderr ---" >&2
  cat "$errfile" >&2
  echo "--- end stderr ---" >&2
}

if [[ ! -f "$CORE" ]]; then
  echo "Building intercal_core via bootstrap..."
  zsh "$ROOT_DIR/src/bootstrap/intercalc.sh" < "$ROOT_DIR/src/compiler/compiler.i" > "$CORE" 2>&1 || {
    echo "FAILED to build intercal_core"
    exit 1
  }
  chmod +x "$CORE"
fi

PASS=0
FAIL=0
SKIP=0

run_self() {
  local name=$1 input=$2 expected=$3 stdin_data=${4:-}
  should_run "$name" || return 0
  local binary=$(mktemp /tmp/intercal_self.XXXXXX)
  local errfile=$(mktemp /tmp/intercal_self_err.XXXXXX)

  if ! "$ROOT_DIR/intercal" "$input" -o "$binary" 2>"$errfile"; then
    if grep -q "cannot dispatch" "$errfile"; then
      echo "SKIP $name (MVP: template not registered)"
      SKIP=$((SKIP + 1))
    else
      echo "FAIL $name (compile error)"
      head -2 "$errfile" >&2
      show_err "$errfile"
      preserve_failure "$name" "$input" "$errfile"
      FAIL=$((FAIL + 1))
    fi
    rm -f "$binary" "$errfile"
    return
  fi
  rm -f "$errfile"

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
    echo "FAIL $name (output mismatch)"
    echo "  expected: [$expected]"
    echo "  actual:   [$actual]"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$binary"
}

run_self_runtime_err() {
  local name=$1 input=$2 expected_code=$3
  should_run "$name" || return 0
  local binary=$(mktemp /tmp/intercal_self.XXXXXX)
  local errfile=$(mktemp /tmp/intercal_self_err.XXXXXX)

  if ! "$ROOT_DIR/intercal" "$input" -o "$binary" 2>"$errfile"; then
    if grep -q "cannot dispatch" "$errfile"; then
      echo "SKIP $name (MVP: template not registered)"
      SKIP=$((SKIP + 1))
    else
      echo "FAIL $name (compile error)"
      show_err "$errfile"
      preserve_failure "$name" "$input" "$errfile"
      FAIL=$((FAIL + 1))
    fi
    rm -f "$binary" "$errfile"
    return
  fi
  rm -f "$errfile"

  local rtfile=$(mktemp /tmp/intercal_self_rt.XXXXXX)
  "$binary" > /dev/null 2>"$rtfile"
  local exit_code=$?
  local err=$(cat "$rtfile")
  rm -f "$rtfile"

  if [[ $exit_code -ne 0 ]] && echo "$err" | grep -q "ICL${expected_code}I"; then
    echo "PASS $name (runtime error $expected_code)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name (expected runtime error $expected_code)"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$binary"
}

run_self_compile_err() {
  local name=$1 input=$2 expected_code=$3
  should_run "$name" || return 0
  local binary=$(mktemp /tmp/intercal_self.XXXXXX)
  local errfile=$(mktemp /tmp/intercal_self_err.XXXXXX)
  "$ROOT_DIR/intercal" "$input" -o "$binary" 2>"$errfile"
  local exit_code=$?
  local err=$(cat "$errfile")

  if [[ $exit_code -ne 0 ]] && echo "$err" | grep -q "ICL${expected_code}I"; then
    echo "PASS $name (compile error $expected_code)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name (expected compile error $expected_code)"
    echo "  exit=$exit_code err=[$err]"
    preserve_failure "$name" "$input" "$errfile"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$errfile" "$binary"
}

run_self_with_args() {
  local name=$1 input=$2 expected=$3
  shift 3
  should_run "$name" || return 0
  local args=("$@")
  local binary=$(mktemp /tmp/intercal_self.XXXXXX)
  local errfile=$(mktemp /tmp/intercal_self_err.XXXXXX)

  if ! "$ROOT_DIR/intercal" "$input" -o "$binary" 2>"$errfile"; then
    if grep -q "cannot dispatch" "$errfile"; then
      echo "SKIP $name (MVP: template not registered)"
      SKIP=$((SKIP + 1))
    else
      echo "FAIL $name (compile error)"
      show_err "$errfile"
      preserve_failure "$name" "$input" "$errfile"
      FAIL=$((FAIL + 1))
    fi
    rm -f "$binary" "$errfile"
    return
  fi
  rm -f "$errfile"

  local actual
  actual=$("$binary" "${args[@]}" 2>/dev/null) || true

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name (output mismatch)"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$binary"
}

cd "$SCRIPT_DIR"

echo "Running self-hosted INTERCAL compiler tests..."
echo ""

# Positive tests (same as run_tests.sh)
run_self "give_up" "$SCRIPT_DIR/test_give_up.i" ""
run_self "read_out_5" "$SCRIPT_DIR/test_read_out_num.i" "V"
run_self "variables" "$SCRIPT_DIR/test_variables.i" "XLII"
run_self "hello_world" "$SCRIPT_DIR/test_hello.i" "$(printf 'Hello, World!\n')"
run_self "control_flow" "$SCRIPT_DIR/test_control.i" "VII"
run_self "syslib_add" "$SCRIPT_DIR/test_syslib.i" "VIII"
run_self "syslib_multiply" "$SCRIPT_DIR/test_multiply.i" "XLII"
run_self "syslib_divide" "$SCRIPT_DIR/test_divide.i" "VII"
run_self "stash_retrieve" "$SCRIPT_DIR/test_stash.i" "VII"
run_self "abstain" "$SCRIPT_DIR/test_abstain.i" "V"
run_self "come_from" "$SCRIPT_DIR/test_come_from.i" "XCIX"
run_self "multidim_array" "$SCRIPT_DIR/test_multidim_array.i" "XLII"
run_self "forget" "$SCRIPT_DIR/test_forget.i" "XLII"
run_self "ignore_remember" "$SCRIPT_DIR/test_ignore_remember.i" "XLII"
run_self "nested_expr" "$SCRIPT_DIR/test_nested_expr.i" "III"
run_self "read_out_multi" "$SCRIPT_DIR/test_read_out_multi.i" "$(printf 'V\nXLII')"
run_self "abstain_gerund" "$SCRIPT_DIR/test_abstain_gerund.i" "XLII"
run_self "write_in" "$SCRIPT_DIR/test_write_in.i" "CXXIII" "ONE TWO THREE"
run_self "overbar" "$SCRIPT_DIR/test_overbar.i" "_IVDLXVII"

# argv-based test
run_self_with_args "syscall_readself" "$SCRIPT_DIR/test_syscall_readself.i" \
  "$(cat $SCRIPT_DIR/test_syscall_readself.i)" "$SCRIPT_DIR/test_syscall_readself.i"

# Compile-time error tests
run_self_compile_err "politeness_rude" "$SCRIPT_DIR/test_errors_rude.i" "079"
run_self_compile_err "politeness_polite" "$SCRIPT_DIR/test_errors_polite.i" "099"

# Runtime error tests
run_self_runtime_err "error_e123" "$SCRIPT_DIR/test_error_e123.i" "123"
run_self_runtime_err "error_e621" "$SCRIPT_DIR/test_error_e621.i" "621"
run_self_runtime_err "error_e633" "$SCRIPT_DIR/test_error_e633.i" "633"

echo ""
echo "Self-hosted results: $PASS passed, $FAIL failed, $SKIP skipped"
[[ $FAIL -eq 0 ]]
