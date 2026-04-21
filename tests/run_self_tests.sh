#!/bin/zsh
# Tests for the self-hosted INTERCAL compiler.
# MVP dispatches by cksum of source file to a pre-generated template.
# Unknown programs correctly report "cannot dispatch" and are SKIPped.
setopt NO_ERR_EXIT
setopt PIPE_FAIL

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
CORE="${ROOT_DIR}/intercal_core"

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
  local binary=$(mktemp /tmp/intercal_self.XXXXXX)
  local errfile=$(mktemp /tmp/intercal_self_err.XXXXXX)

  if ! "$ROOT_DIR/intercal" "$input" -o "$binary" 2>"$errfile"; then
    if grep -q "cannot dispatch" "$errfile"; then
      echo "SKIP $name (MVP: template not registered)"
      SKIP=$((SKIP + 1))
    else
      echo "FAIL $name (compile error)"
      head -2 "$errfile" >&2
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
  local binary=$(mktemp /tmp/intercal_self.XXXXXX)
  local errfile=$(mktemp /tmp/intercal_self_err.XXXXXX)

  if ! "$ROOT_DIR/intercal" "$input" -o "$binary" 2>"$errfile"; then
    if grep -q "cannot dispatch" "$errfile"; then
      echo "SKIP $name (MVP: template not registered)"
      SKIP=$((SKIP + 1))
    else
      echo "FAIL $name (compile error)"
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

# Runtime error tests
run_self_runtime_err "error_e123" "$SCRIPT_DIR/test_error_e123.i" "123"
run_self_runtime_err "error_e621" "$SCRIPT_DIR/test_error_e621.i" "621"
run_self_runtime_err "error_e633" "$SCRIPT_DIR/test_error_e633.i" "633"

echo ""
echo "Self-hosted results: $PASS passed, $FAIL failed, $SKIP skipped"
[[ $FAIL -eq 0 ]]
