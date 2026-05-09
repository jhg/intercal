#!/bin/zsh
# Minimal INTERCAL bytecode interpreter. Reads bytecode on stdin
# (one instruction per line), executes, prints output to stdout.
set -euo pipefail

typeset -A spot

# Convert integer 0..3999 to Roman numerals (matching READ OUT).
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

while IFS= read -r line; do
  line="${line## }"
  line="${line%% }"
  [[ -z "$line" ]] && continue
  set -- ${(z)line}
  case "$1" in
    LOADI)
      spot[$2]=$3
      ;;
    READOUT)
      to_roman "${spot[$2]:-0}"
      ;;
    EXIT)
      exit 0
      ;;
    *)
      echo "VM ERROR: unknown opcode: $line" >&2
      exit 1
      ;;
  esac
done
