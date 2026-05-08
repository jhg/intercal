#!/bin/zsh
# Csmith-INTERCAL: random INTERCAL program generator for differential testing.
#
# Generates programs in a deliberately small "safe" subset of INTERCAL
# where the output is computable in pure shell at generation time.
# Intended use: pipe stdout into a compiler, run the binary, compare
# stdout against the printed expected-output file. The generator is
# deterministic given a seed.
#
# Subset constraints:
#   - Only spot variables (.1..) with values 0..65530 (avoid overflow
#     boundary issues during E275 detection on assignments).
#   - Only constant assignments: DO .V <- #N
#   - Politeness ratio kept inside [1/5, 1/3]: every 4th statement is
#     PLEASE. With at least 5 statements this lands in [20%, 33%].
#   - At most one READ OUT to print the final value (Roman numerals).
#   - Always ends with PLEASE GIVE UP (counts as polite).
#
# The expected output is a single Roman numeral (the value of the last
# READ OUT), printable from the assigned variable's known value.
#
# Usage:
#   tools/csmith_intercal.sh SEED [PROGRAM_FILE EXPECTED_FILE]
#
# If PROGRAM_FILE/EXPECTED_FILE are omitted, prints the program to
# stdout and the expected output to fd 3 (so callers can capture).

set -euo pipefail

SEED="${1:-1}"
PROG_OUT="${2:-/dev/stdout}"
EXP_OUT="${3:-/dev/null}"

# Reset random-state via seed
RANDOM=$SEED

# Generate N statements (5-12), each an assignment to a variable .1..5
# with a value 0..1000. Keep last value to compute expected output.
n_stmts=$(( 5 + (RANDOM % 4) ))   # 5..8
last_var=0
last_val=0

# Convert integer 0..3999 to Roman numerals (matching READ OUT semantics).
to_roman() {
  local n=$1
  local r=""
  local -a vals=(1000 900 500 400 100 90 50 40 10 9 5 4 1)
  local -a syms=("M" "CM" "D" "CD" "C" "XC" "L" "XL" "X" "IX" "V" "IV" "I")
  if (( n == 0 )); then
    echo ""
    return
  fi
  local i
  for (( i=1; i<=${#vals[@]}; i++ )); do
    while (( n >= vals[i] )); do
      r+="${syms[i]}"
      n=$(( n - vals[i] ))
    done
  done
  echo "$r"
}

prog=""
i=0
while (( i < n_stmts )); do
  local var=$(( 1 + (RANDOM % 5) ))
  local val=$(( RANDOM % 100 + 1 ))
  if (( i % 4 == 0 && i > 0 )); then
    prog+="PLEASE DO .${var} <- #${val}"$'\n'
  else
    prog+="DO .${var} <- #${val}"$'\n'
  fi
  last_var=$var
  last_val=$val
  i=$((i+1))
done

# Final two statements: READ OUT .last_var, PLEASE GIVE UP
prog+="DO READ OUT .${last_var}"$'\n'
prog+="PLEASE GIVE UP"$'\n'

expected=$(to_roman "$last_val")

print -r -- "$prog" > "$PROG_OUT"
print -r -- "$expected" > "$EXP_OUT"
