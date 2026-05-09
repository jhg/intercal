#!/bin/zsh
# INTERCAL bytecode interpreter. Reads bytecode on stdin, executes,
# prints output to stdout.
set -euo pipefail

typeset -A spot
typeset -A twospot
typeset -A spot_ign
typeset -A twospot_ign
typeset -A spot_stash      # stack of past values
typeset -A twospot_stash

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

stash_push() {
  local kind=$1 var=$2 val=$3
  case "$kind" in
    spot)
      local cur="${spot_stash[$var]:-}"
      spot_stash[$var]="${val} ${cur}"
      ;;
    twospot)
      local cur="${twospot_stash[$var]:-}"
      twospot_stash[$var]="${val} ${cur}"
      ;;
  esac
}

stash_pop() {
  local kind=$1 var=$2
  case "$kind" in
    spot)
      local cur="${spot_stash[$var]:-}"
      if [[ -z "$cur" ]]; then
        echo "ICL436I retrieve from empty stash on .${var}" >&2
        exit 1
      fi
      REPLY="${cur%% *}"
      spot_stash[$var]="${cur#* }"
      [[ "${spot_stash[$var]}" == "$cur" ]] && spot_stash[$var]=""
      ;;
    twospot)
      local cur="${twospot_stash[$var]:-}"
      if [[ -z "$cur" ]]; then
        echo "ICL436I retrieve from empty stash on :${var}" >&2
        exit 1
      fi
      REPLY="${cur%% *}"
      twospot_stash[$var]="${cur#* }"
      [[ "${twospot_stash[$var]}" == "$cur" ]] && twospot_stash[$var]=""
      ;;
  esac
}

while IFS= read -r line; do
  line="${line## }"
  line="${line%% }"
  [[ -z "$line" ]] && continue
  set -- ${(z)line}
  case "$1" in
    LOADI)
      [[ -n "${spot_ign[$2]:-}" ]] && continue
      spot[$2]=$3
      ;;
    LOADI2)
      [[ -n "${twospot_ign[$2]:-}" ]] && continue
      twospot[$2]=$3
      ;;
    COPY)
      [[ -n "${spot_ign[$2]:-}" ]] && continue
      spot[$2]="${spot[$3]:-0}"
      ;;
    COPY2)
      [[ -n "${twospot_ign[$2]:-}" ]] && continue
      twospot[$2]="${twospot[$3]:-0}"
      ;;
    READOUT)
      to_roman "${spot[$2]:-0}"
      ;;
    READOUT2)
      to_roman "${twospot[$2]:-0}"
      ;;
    STASH)
      stash_push spot $2 "${spot[$2]:-0}"
      ;;
    RETRIEVE)
      stash_pop spot $2
      [[ -n "${spot_ign[$2]:-}" ]] || spot[$2]="$REPLY"
      ;;
    IGNORE)
      spot_ign[$2]=1
      ;;
    REMEMBER)
      unset "spot_ign[$2]"
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
