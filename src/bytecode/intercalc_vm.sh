#!/bin/zsh
# INTERCAL bytecode interpreter. Stack-based VM.
set -euo pipefail

typeset -A spot
typeset -A twospot
typeset -A spot_ign
typeset -A twospot_ign
typeset -A spot_stash
typeset -A twospot_stash
typeset -a stack

push() { stack+=("$1") }
pop()  {
  if (( ${#stack} == 0 )); then
    echo "VM ERROR: stack underflow" >&2
    exit 1
  fi
  REPLY="${stack[-1]}"
  stack=("${stack[@]:0:-1}")
}

to_roman() {
  local n=$1
  local r=""
  local -a vals=(1000 900 500 400 100 90 50 40 10 9 5 4 1)
  local -a syms=("M" "CM" "D" "CD" "C" "XC" "L" "XL" "X" "IX" "V" "IV" "I")
  if (( n == 0 )); then echo ""; return; fi
  local i=""
  for (( i=1; i<=${#vals[@]}; i++ )); do
    while (( n >= vals[i] )); do
      r+="${syms[i]}"
      n=$(( n - vals[i] ))
    done
  done
  echo "$r"
}

# Mingle (16-bit a, 16-bit b) -> 32-bit interleave
do_mingle() {
  local b=$1 a=$2
  local result=0 i
  for (( i=0; i<16; i++ )); do
    local ba=$(( (a >> i) & 1 ))
    local bb=$(( (b >> i) & 1 ))
    result=$(( result | (ba << (2*i + 1)) | (bb << (2*i)) ))
  done
  echo "$result"
}

# Select bits of val where mask has a 1, packed right-justified.
do_select() {
  local mask=$1 val=$2
  local result=0 outpos=0 i
  for (( i=0; i<32; i++ )); do
    if (( (mask >> i) & 1 )); then
      result=$(( result | (((val >> i) & 1) << outpos) ))
      outpos=$((outpos + 1))
    fi
  done
  echo "$result"
}

# Unary AND/OR/XOR of adjacent bits with wrap, 16-bit width by default.
do_unary() {
  local op=$1 v=$2 width=$3
  local mask=$(( (1 << width) - 1 ))
  v=$(( v & mask ))
  local rot=$(( ((v >> 1) | ((v & 1) << (width - 1))) & mask ))
  case "$op" in
    AND) echo $(( (v & rot) & mask )) ;;
    OR)  echo $(( (v | rot) & mask )) ;;
    XOR) echo $(( (v ^ rot) & mask )) ;;
  esac
}

stash_push() {
  local kind=$1 var=$2 val=$3
  case "$kind" in
    spot) spot_stash[$var]="${val} ${spot_stash[$var]:-}" ;;
    twospot) twospot_stash[$var]="${val} ${twospot_stash[$var]:-}" ;;
  esac
}

stash_pop() {
  local kind=$1 var=$2
  case "$kind" in
    spot)
      local cur="${spot_stash[$var]:-}"
      if [[ -z "$cur" ]]; then echo "ICL436I retrieve from empty stash on .${var}" >&2; exit 1; fi
      REPLY="${cur%% *}"
      local rest="${cur#* }"
      [[ "$rest" == "$cur" ]] && rest=""
      spot_stash[$var]="$rest"
      ;;
    twospot)
      local cur="${twospot_stash[$var]:-}"
      if [[ -z "$cur" ]]; then echo "ICL436I retrieve from empty stash on :${var}" >&2; exit 1; fi
      REPLY="${cur%% *}"
      local rest="${cur#* }"
      [[ "$rest" == "$cur" ]] && rest=""
      twospot_stash[$var]="$rest"
      ;;
  esac
}

while IFS= read -r line; do
  line="${line## }"
  line="${line%% }"
  [[ -z "$line" ]] && continue
  set -- ${(z)line}
  case "$1" in
    IPUSH) push "$2" ;;
    VPUSH)
      local v="${2#.}"
      push "${spot[$v]:-0}"
      ;;
    VPUSH2)
      local v="${2#:}"
      push "${twospot[$v]:-0}"
      ;;
    POPV)
      local v="${2#.}"
      pop
      [[ -n "${spot_ign[$v]:-}" ]] || spot[$v]="$REPLY"
      ;;
    POPV2)
      local v="${2#:}"
      pop
      [[ -n "${twospot_ign[$v]:-}" ]] || twospot[$v]="$REPLY"
      ;;
    MINGLE)
      pop; local rb=$REPLY
      pop; local ra=$REPLY
      push "$(do_mingle $rb $ra)"
      ;;
    SELECT)
      pop; local rmask=$REPLY
      pop; local rval=$REPLY
      push "$(do_select $rmask $rval)"
      ;;
    UAND)
      pop; push "$(do_unary AND $REPLY 16)"
      ;;
    UOR)
      pop; push "$(do_unary OR $REPLY 16)"
      ;;
    UXOR)
      pop; push "$(do_unary XOR $REPLY 16)"
      ;;
    READOUT)
      pop
      to_roman "$REPLY"
      ;;
    READOUT2)
      pop
      to_roman "$REPLY"
      ;;
    STASH)
      local v="${2#.}"; local kind=spot
      [[ "$2" == :* ]] && { v="${2#:}"; kind=twospot; }
      if [[ "$kind" == "spot" ]]; then
        stash_push spot "$v" "${spot[$v]:-0}"
      else
        stash_push twospot "$v" "${twospot[$v]:-0}"
      fi
      ;;
    RETRIEVE)
      local v="${2#.}"; local kind=spot
      [[ "$2" == :* ]] && { v="${2#:}"; kind=twospot; }
      stash_pop "$kind" "$v"
      if [[ "$kind" == "spot" ]]; then
        [[ -n "${spot_ign[$v]:-}" ]] || spot[$v]="$REPLY"
      else
        [[ -n "${twospot_ign[$v]:-}" ]] || twospot[$v]="$REPLY"
      fi
      ;;
    IGNORE)
      local v="${2#.}"; [[ "$2" == :* ]] && { twospot_ign[${2#:}]=1; continue; }
      spot_ign[$v]=1
      ;;
    REMEMBER)
      if [[ "$2" == :* ]]; then unset "twospot_ign[${2#:}]"
      else unset "spot_ign[${2#.}]"; fi
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
