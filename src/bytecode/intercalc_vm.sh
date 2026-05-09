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

# Buffer all ops then run them PC-driven so we can handle COME FROM
# redirects. The streaming line-at-a-time model used previously cannot
# express backward (or forward) jumps.
typeset -a ops_buf
while IFS= read -r line; do
  line="${line## }"
  line="${line%% }"
  [[ -z "$line" ]] && continue
  ops_buf+=("$line")
done

# Pre-scan: build the redirect map from labels to the PC immediately
# AFTER the matching COMEFROM line. The label fires at a labelled
# stmt's ESTMT boundary; control transfers to whatever lies after the
# COMEFROM op. By construction the bytecode emits an ESTMT after the
# COMEFROM line, so the redirect target is "just past the ESTMT after
# the COMEFROM" — i.e., the PC of the next non-ESTMT op.
typeset -A redirect_target
typeset pc_scan=0
for (( pc_scan=0; pc_scan<${#ops_buf[@]}; pc_scan++ )); do
  local op="${ops_buf[$((pc_scan+1))]}"
  if [[ "$op" =~ '^COMEFROM ([0-9]+)$' ]]; then
    local lbl="${match[1]}"
    # Target is past the COMEFROM and its ESTMT.
    local target=$((pc_scan + 2))
    redirect_target[$lbl]=$target
  fi
done

# pending_label: set when a LABEL op is executed; checked at ESTMT.
typeset pending_label=""
typeset pc=0
while (( pc < ${#ops_buf[@]} )); do
  local line="${ops_buf[$((pc+1))]}"
  pc=$((pc + 1))
  set -- ${(z)line}
  case "$1" in
    LABEL)
      pending_label="$2"
      ;;
    COMEFROM)
      # Already processed in the pre-scan; treat as a no-op.
      ;;
    ESTMT)
      if [[ -n "$pending_label" ]] && (( ${+redirect_target[$pending_label]} )); then
        pc=${redirect_target[$pending_label]}
      fi
      pending_label=""
      ;;
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
