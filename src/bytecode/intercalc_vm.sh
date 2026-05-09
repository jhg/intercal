#!/bin/zsh
# INTERCAL bytecode interpreter. Stack-based VM.
set -euo pipefail

typeset -A spot
typeset -A twospot
typeset -A spot_ign
typeset -A twospot_ign
typeset -A spot_stash
typeset -A twospot_stash
typeset -A array_data    # key: '<pfx><num>:<flat_idx>' -> value
typeset -A array_dim     # key: '<pfx><num>' -> size (legacy 1D, set when ndims=1)
typeset -A array_dims    # key: '<pfx><num>' -> 'd1 d2 d3 ...' (per-dim sizes)
typeset -i ttm_out_pos=0 # output tape head (Turing Text Model)
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

typeset -A spot_stash_depth twospot_stash_depth
stash_push() {
  local kind=$1 var=$2 val=$3
  # Enforce per-variable stash depth limit (1024 entries, matching
  # the native runtime's _stash_sp[1023] cap). O(1): incremented
  # depth counter rather than scanning the stash string.
  case "$kind" in
    spot)
      local d=${spot_stash_depth[$var]:-0}
      if (( d >= 1023 )); then
        echo "ICL000I per-var stash overflow on .${var}" >&2
        exit 1
      fi
      spot_stash[$var]="${val} ${spot_stash[$var]:-}"
      spot_stash_depth[$var]=$((d + 1))
      ;;
    twospot)
      local d=${twospot_stash_depth[$var]:-0}
      if (( d >= 1023 )); then
        echo "ICL000I per-var stash overflow on :${var}" >&2
        exit 1
      fi
      twospot_stash[$var]="${val} ${twospot_stash[$var]:-}"
      twospot_stash_depth[$var]=$((d + 1))
      ;;
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
      spot_stash_depth[$var]=$((${spot_stash_depth[$var]:-1} - 1))
      ;;
    twospot)
      local cur="${twospot_stash[$var]:-}"
      if [[ -z "$cur" ]]; then echo "ICL436I retrieve from empty stash on :${var}" >&2; exit 1; fi
      REPLY="${cur%% *}"
      local rest="${cur#* }"
      [[ "$rest" == "$cur" ]] && rest=""
      twospot_stash[$var]="$rest"
      twospot_stash_depth[$var]=$((${twospot_stash_depth[$var]:-1} - 1))
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

# Pre-scan: build maps:
#   redirect_target[label] = pc immediately after the COMEFROM's ESTMT
#                            (used by labelled statements to redirect)
#   label_pc[label]        = pc of the labelled statement (CALL target)
#   stmt_end_pc[id]        = pc of the ESTMT that closes statement id
#   label_to_stmt_id[lbl]  = stmt id of the labelled statement
typeset -A redirect_target
typeset -A label_pc
typeset -A stmt_end_pc
typeset -A label_to_stmt_id
typeset -A stmt_type_of_id    # stmt_id -> gerund-style type
typeset -A ids_by_gerund      # gerund -> space-separated id list
typeset -a abstain
typeset pc_scan=0
typeset cur_stmt_id=0
typeset cur_classified=0
for (( pc_scan=0; pc_scan<${#ops_buf[@]}; pc_scan++ )); do
  local op="${ops_buf[$((pc_scan+1))]}"
  if [[ "$op" =~ '^COMEFROM ([0-9]+)$' ]]; then
    local lbl="${match[1]}"
    local target=$((pc_scan + 2))
    redirect_target[$lbl]=$target
  elif [[ "$op" =~ '^LABEL ([0-9]+)$' ]]; then
    label_pc[${match[1]}]=$((pc_scan + 1))
    label_to_stmt_id[${match[1]}]=$cur_stmt_id
  elif [[ "$op" =~ '^STMT_ENTER ([0-9]+)$' ]]; then
    cur_stmt_id="${match[1]}"
    abstain[$cur_stmt_id]=0
    cur_classified=0
  elif [[ "$op" == "ESTMT" ]] && (( cur_stmt_id > 0 )); then
    stmt_end_pc[$cur_stmt_id]=$pc_scan
  elif (( cur_stmt_id > 0 )) && (( ! cur_classified )); then
    # Classify this statement by its first op (ignoring LABEL).
    local _ger=""
    case "${op%% *}" in
      LABEL) ;;  # skip, look at next op
      POPV|POPV2) _ger="CALCULATING" ;;
      CALL) _ger="NEXTING" ;;
      RESUME) _ger="RESUMING" ;;
      FORGET) _ger="FORGETTING" ;;
      STASH) _ger="STASHING" ;;
      RETRIEVE) _ger="RETRIEVING" ;;
      IGNORE) _ger="IGNORING" ;;
      REMEMBER) _ger="REMEMBERING" ;;
      ABSTAIN_LBL|ABSTAIN_GER) _ger="ABSTAINING" ;;
      REINSTATE_LBL|REINSTATE_GER) _ger="REINSTATING" ;;
      COMEFROM) _ger="COMING_FROM" ;;
      VPUSH|VPUSH2|IPUSH) ;;  # part of expression, look further
      READOUT|READOUT2) _ger="READING_OUT" ;;
      WRITEIN) _ger="WRITING_IN" ;;
    esac
    if [[ -n "$_ger" ]]; then
      stmt_type_of_id[$cur_stmt_id]="$_ger"
      ids_by_gerund[$_ger]="${ids_by_gerund[$_ger]:-} $cur_stmt_id"
      cur_classified=1
    fi
  fi
done

# pending_label: set when a LABEL op is executed; checked at ESTMT.
# call_stack: NEXT pushes the return PC, RESUME pops, FORGET drops.
typeset pending_label=""
typeset -a call_stack
call_stack=()
typeset pc=0
while (( pc < ${#ops_buf[@]} )); do
  local line="${ops_buf[$((pc+1))]}"
  pc=$((pc + 1))
  set -- ${(z)line}
  case "$1" in
    STMT_ENTER)
      # If this stmt is currently abstained, jump past its ESTMT.
      local _sid="$2"
      if (( ${abstain[$_sid]:-0} )); then
        if (( ${+stmt_end_pc[$_sid]} )); then
          pc=$((${stmt_end_pc[$_sid]} + 1))
        fi
      fi
      ;;
    PROB)
      # Roll a 0..99 random and skip the rest of the stmt if the
      # roll is >= the percentage. Use the most recently set
      # pending_label's stmt id if available, otherwise fall back
      # to forward-scan; tracking the current stmt id explicitly
      # avoids ambiguity if future ops introduce nested ESTMTs.
      local _pct="$2"
      if (( (RANDOM % 100) >= _pct )); then
        # We don't track current_stmt_id during execution (only the
        # pre-scan does). Forward-scan to the next ESTMT; safe today
        # because INTERCAL stmts don't nest.
        local _scan=$pc
        while (( _scan < ${#ops_buf[@]} )); do
          local _o="${ops_buf[$((_scan+1))]}"
          if [[ "$_o" == "ESTMT" ]]; then
            pc=$((_scan + 1))
            break
          fi
          # Defensive: if we hit another STMT_ENTER first, the
          # statement is malformed (no ESTMT before next stmt).
          if [[ "$_o" == "STMT_ENTER "* ]]; then
            echo "VM ERROR: PROB found STMT_ENTER before ESTMT" >&2
            exit 1
          fi
          _scan=$((_scan + 1))
        done
      fi
      ;;
    ABSTAIN_LBL)
      local _lbl="$2"
      if (( ${+label_to_stmt_id[$_lbl]} )); then
        abstain[${label_to_stmt_id[$_lbl]}]=1
      fi
      ;;
    REINSTATE_LBL)
      local _lbl="$2"
      if (( ${+label_to_stmt_id[$_lbl]} )); then
        abstain[${label_to_stmt_id[$_lbl]}]=0
      fi
      ;;
    ABSTAIN_GER)
      local _ger="$2"
      local _id=""
      for _id in ${=ids_by_gerund[$_ger]:-}; do
        abstain[$_id]=1
      done
      ;;
    REINSTATE_GER)
      local _ger="$2"
      local _id=""
      for _id in ${=ids_by_gerund[$_ger]:-}; do
        abstain[$_id]=0
      done
      ;;
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
    BRANCH)
      # NEXT FROM (N) unconditional: jump to label without stack push.
      local target_lbl="$2"
      if (( ! ${+label_pc[$target_lbl]} )); then
        echo "ICL129I PROGRAM HAS GOTTEN LOST (NEXT FROM to undefined label $target_lbl)" >&2
        exit 1
      fi
      pc=${label_pc[$target_lbl]}
      ;;
    BRANCH_NZ)
      # NEXT FROM (N) <expr>: pop expression result, jump if bit 0 set.
      local target_lbl="$2"
      pop
      if (( REPLY & 1 )); then
        if (( ! ${+label_pc[$target_lbl]} )); then
          echo "ICL129I PROGRAM HAS GOTTEN LOST (NEXT FROM to undefined label $target_lbl)" >&2
          exit 1
        fi
        pc=${label_pc[$target_lbl]}
      fi
      ;;
    CALL)
      # NEXT to label N: push current pc as return target, jump to
      # the labelled statement's PC. Stack overflow at 80 mirrors
      # the runtime contract.
      local target_lbl="$2"
      # Syslib labels (1000-1999) and Label 666 get evaluated in the
      # VM directly rather than via a labelled-stmt jump.
      if (( target_lbl == 666 )) \
         || (( target_lbl >= 1000 && target_lbl < 2000 )); then
        case "$target_lbl" in
          1000)
            # .3 = .1 + .2; per AGENTS.md the runtime does NOT
            # actually error on overflow (the (1801) no-overflow
            # path always wins per Note in bugs_learned). Match
            # native behaviour: silent wrap.
            local _v1=${spot[1]:-0} _v2=${spot[2]:-0}
            spot[3]=$(( (_v1 + _v2) & 0xFFFF ))
            ;;
          1009)
            local _v1=${spot[1]:-0} _v2=${spot[2]:-0}
            local _sum=$(( _v1 + _v2 ))
            spot[3]=$(( _sum & 0xFFFF ))
            spot[4]=$(( _sum > 65535 ? 2 : 1 ))
            ;;
          1010)
            local _v1=${spot[1]:-0} _v2=${spot[2]:-0}
            spot[3]=$(( (_v1 - _v2 + 65536) & 0xFFFF ))
            ;;
          1020)
            local _v1=${spot[1]:-0}
            spot[1]=$(( (_v1 + 1) & 0xFFFF ))
            ;;
          1030)
            local _v1=${spot[1]:-0} _v2=${spot[2]:-0}
            local _prod=$(( _v1 * _v2 ))
            if (( _prod > 65535 )); then
              echo "ICL533I YOU WANT MAYBE TO DIVIDE BY ZERO?" >&2
              exit 1
            fi
            spot[3]=$_prod
            ;;
          1040)
            local _v1=${spot[1]:-0} _v2=${spot[2]:-0}
            if (( _v2 == 0 )); then spot[3]=0; else spot[3]=$(( _v1 / _v2 )); fi
            ;;
          1050)
            local _v1=${twospot[1]:-0} _vd=${spot[1]:-0}
            if (( _vd == 0 )); then
              spot[2]=0
            else
              local _q=$(( _v1 / _vd ))
              if (( _q > 65535 )); then
                echo "ICL533I" >&2; exit 1
              fi
              spot[2]=$_q
            fi
            ;;
          1500)
            local _v1=${twospot[1]:-0} _v2=${twospot[2]:-0}
            local _sum=$(( _v1 + _v2 ))
            if (( _sum > 4294967295 )); then
              echo "ICL533I" >&2; exit 1
            fi
            twospot[3]=$_sum
            ;;
          1509)
            local _v1=${twospot[1]:-0} _v2=${twospot[2]:-0}
            local _sum=$(( _v1 + _v2 ))
            twospot[3]=$(( _sum & 0xFFFFFFFF ))
            twospot[4]=$(( _sum > 4294967295 ? 2 : 1 ))
            ;;
          1510)
            local _v1=${twospot[1]:-0} _v2=${twospot[2]:-0}
            twospot[3]=$(( (_v1 - _v2 + 4294967296) & 0xFFFFFFFF ))
            ;;
          1520)
            local _v1=${spot[1]:-0} _v2=${spot[2]:-0}
            local _result=0 _j=0
            for (( _j=0; _j<16; _j++ )); do
              local _b1=$(( (_v1 >> _j) & 1 ))
              local _b2=$(( (_v2 >> _j) & 1 ))
              _result=$(( _result | (_b1 << (2*_j + 1)) | (_b2 << (2*_j)) ))
            done
            twospot[1]=$_result
            ;;
          1530)
            local _v1=${spot[1]:-0} _v2=${spot[2]:-0}
            twospot[1]=$(( _v1 * _v2 ))
            ;;
          1540)
            local _v1=${twospot[1]:-0} _v2=${twospot[2]:-0}
            local _prod=$(( _v1 * _v2 ))
            if (( _prod > 4294967295 )); then
              echo "ICL533I" >&2; exit 1
            fi
            twospot[3]=$_prod
            ;;
          1549)
            local _v1=${twospot[1]:-0} _v2=${twospot[2]:-0}
            local _prod=$(( _v1 * _v2 ))
            twospot[3]=$(( _prod & 0xFFFFFFFF ))
            twospot[4]=$(( _prod > 4294967295 ? 2 : 1 ))
            ;;
          1550)
            local _v1=${twospot[1]:-0} _v2=${twospot[2]:-0}
            if (( _v2 == 0 )); then twospot[3]=0; else twospot[3]=$(( _v1 / _v2 )); fi
            ;;
          1900)
            spot[1]=$(( RANDOM % 65536 ))
            ;;
          1910)
            local _max=${spot[1]:-0}
            (( _max == 0 )) && spot[2]=0 || spot[2]=$(( RANDOM % (_max + 1) ))
            ;;
          666)
            # Label 666: dispatch by .1 (syscall number).
            local _syscall=${spot[1]:-0}
            case "$_syscall" in
              5)
                # argc: count of program args (excluding the VM
                # script path). With our harness 'vm < bytecode',
                # argv is empty; report 0.
                spot[3]=${#argv}
                ;;
              6)
                # argv index .2 -> length in .3, content in ,65535.
                local _ai=${spot[2]:-0}
                if (( _ai >= 0 )) && (( _ai < ${#argv} )); then
                  local _arg="${argv[$((_ai + 1))]}"
                  local _len=${#_arg}
                  spot[3]=$_len
                  # Set ,65535 to dim _len, store bytes.
                  array_dims[,65535]="$_len"
                  array_dim[,65535]=$_len
                  local _ci=0
                  for (( _ci=0; _ci<_len; _ci++ )); do
                    local _ch="${_arg[$((_ci + 1))]}"
                    array_data[,65535:${_ci}]=$(printf '%d' "'$_ch")
                  done
                else
                  spot[3]=0
                fi
                ;;
              8)
                exit ${spot[2]:-0}
                ;;
              9)
                # getrand: .2=0 means uniform, .2>0 means range 0..N
                local _max=${spot[2]:-0}
                if (( _max == 0 )); then
                  spot[3]=$(( RANDOM % 65536 ))
                else
                  spot[3]=$(( RANDOM % (_max + 1) ))
                fi
                ;;
              *)
                echo "VM ERROR: Label 666 syscall $_syscall not implemented in BC" >&2
                exit 1
                ;;
            esac
            ;;
          *)
            echo "VM ERROR: unsupported syslib label $target_lbl" >&2
            exit 1
            ;;
        esac
        # Syslib calls don't push the call stack — they're modeled as
        # instantaneous in this VM. PC continues to next op.
      else
        if (( ${#call_stack[@]} >= 79 )); then
          echo "ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON" >&2
          exit 1
        fi
        if (( ! ${+label_pc[$target_lbl]} )); then
          echo "ICL129I PROGRAM HAS GOTTEN LOST (NEXT to undefined label $target_lbl)" >&2
          exit 1
        fi
        call_stack+=("$pc")
        pc=${label_pc[$target_lbl]}
      fi
      ;;
    RESUME)
      # Pop N entries; the LAST popped PC is the return target.
      local n="$2"
      if (( n == 0 )); then
        echo "ICL621I ERROR TYPE 621 ENCOUNTERED" >&2
        exit 1
      fi
      if (( n > ${#call_stack[@]} )); then
        echo "ICL632I PROGRAM ENDED VIA RESUME INSTEAD OF GIVE UP" >&2
        exit 1
      fi
      local return_pc=0
      local k=0
      for (( k=0; k<n; k++ )); do
        return_pc="${call_stack[-1]}"
        call_stack=("${call_stack[@]:0:-1}")
      done
      pc="$return_pc"
      ;;
    FORGET)
      local n="$2"
      local k=0
      for (( k=0; k<n && ${#call_stack[@]} > 0; k++ )); do
        call_stack=("${call_stack[@]:0:-1}")
      done
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
    WRITEIN)
      # Read one line of user input. Bytecode comes from stdin, so
      # WRITE IN data must come from fd 3 (caller does
      # 'vm 3<input.txt < bytecode'). If fd 3 is not open, read from
      # /dev/tty (interactive use).
      local _line=""
      if { true >&3; } 2>/dev/null; then
        IFS= read -r -u 3 _line
      else
        IFS= read -r _line < /dev/tty 2>/dev/null || _line=""
      fi
      typeset -A _digit
      _digit[OH]=0 _digit[ZERO]=0
      _digit[ONE]=1 _digit[TWO]=2 _digit[THREE]=3
      _digit[FOUR]=4 _digit[FIVE]=5 _digit[SIX]=6
      _digit[SEVEN]=7 _digit[EIGHT]=8 _digit[NINE]=9
      local _val=0 _word=""
      for _word in ${(s: :)${(U)_line}}; do
        if (( ! ${+_digit[$_word]} )); then
          echo "ICL579I WHAT IS ALL THIS RACKET?" >&2
          exit 1
        fi
        _val=$(( _val * 10 + _digit[$_word] ))
      done
      if [[ "$2" == :* ]]; then
        local _v="${2#:}"
        [[ -n "${twospot_ign[$_v]:-}" ]] || twospot[$_v]=$_val
      else
        local _v="${2#.}"
        if (( _val > 65535 )); then
          echo "ICL275I DON'T BYTE OFF MORE THAN YOU CAN CHEW" >&2
          exit 1
        fi
        [[ -n "${spot_ign[$_v]:-}" ]] || spot[$_v]=$_val
      fi
      ;;
    DIM)
      pop
      local _dim=$REPLY
      if (( _dim == 0 )); then
        echo "ICL240I ERROR TYPE 240 ENCOUNTERED" >&2
        exit 1
      fi
      array_dim[$2]=$_dim
      array_dims[$2]="$_dim"
      ;;
    DIM_N)
      # 'DIM_N <arr> <ndims>' — pop ndims dims (last-pushed is last
      # dim) and store the dim list. Set legacy array_dim only when
      # ndims=1 so 1D AGET/APUT still works.
      local _arr="$2"
      local _nd="$3"
      local -a _dlist
      _dlist=()
      local _di=0
      for (( _di=0; _di<_nd; _di++ )); do
        pop; _dlist=("$REPLY" "${_dlist[@]}")
      done
      local _d=""
      for _d in "${_dlist[@]}"; do
        if (( _d == 0 )); then
          echo "ICL240I ERROR TYPE 240 ENCOUNTERED" >&2
          exit 1
        fi
      done
      array_dims[$_arr]="${_dlist[*]}"
      if (( _nd == 1 )); then
        array_dim[$_arr]="${_dlist[1]}"
      fi
      ;;
    APUT_N)
      local _arr="$2"
      local _nd="$3"
      pop; local _val=$REPLY
      local -a _slist
      _slist=()
      local _si=0
      for (( _si=0; _si<_nd; _si++ )); do
        pop; _slist=("$REPLY" "${_slist[@]}")
      done
      if [[ -z "${array_dims[$_arr]:-}" ]]; then
        echo "ICL241I undimensioned" >&2; exit 1
      fi
      local -a _dlist
      _dlist=(${=array_dims[$_arr]})
      if (( ${#_slist[@]} != ${#_dlist[@]} )); then
        echo "ICL241I subscript count mismatch" >&2; exit 1
      fi
      # Compute flat index: ((s1-1) * d2 + (s2-1)) * d3 + (s3-1) ...
      local _flat=0
      local _idx=0
      for (( _idx=1; _idx<=_nd; _idx++ )); do
        local _s="${_slist[$_idx]}"
        local _d="${_dlist[$_idx]}"
        if (( _s < 1 || _s > _d )); then
          echo "ICL241I out of range (sub=$_s dim=$_d)" >&2; exit 1
        fi
        _flat=$(( _flat * _d + (_s - 1) ))
      done
      array_data[${_arr}:${_flat}]=$_val
      ;;
    AGET_N)
      local _arr="$2"
      local _nd="$3"
      local -a _slist
      _slist=()
      local _si=0
      for (( _si=0; _si<_nd; _si++ )); do
        pop; _slist=("$REPLY" "${_slist[@]}")
      done
      if [[ -z "${array_dims[$_arr]:-}" ]]; then
        echo "ICL241I undimensioned" >&2; exit 1
      fi
      local -a _dlist
      _dlist=(${=array_dims[$_arr]})
      if (( ${#_slist[@]} != ${#_dlist[@]} )); then
        echo "ICL241I subscript count mismatch" >&2; exit 1
      fi
      local _flat=0
      local _idx=0
      for (( _idx=1; _idx<=_nd; _idx++ )); do
        local _s="${_slist[$_idx]}"
        local _d="${_dlist[$_idx]}"
        if (( _s < 1 || _s > _d )); then
          echo "ICL241I out of range" >&2; exit 1
        fi
        _flat=$(( _flat * _d + (_s - 1) ))
      done
      push "${array_data[${_arr}:${_flat}]:-0}"
      ;;
    APUT)
      pop; local _val=$REPLY
      pop; local _idx=$REPLY
      if (( ! ${+array_dim[$2]} )); then
        echo "ICL241I ERROR TYPE 241 ENCOUNTERED (undimensioned)" >&2
        exit 1
      fi
      if (( _idx < 1 || _idx > ${array_dim[$2]} )); then
        echo "ICL241I ERROR TYPE 241 ENCOUNTERED (out of range)" >&2
        exit 1
      fi
      array_data[${2}:${_idx}]=$_val
      ;;
    AGET)
      pop; local _idx=$REPLY
      if (( ! ${+array_dim[$2]} )); then
        echo "ICL241I ERROR TYPE 241 ENCOUNTERED (undimensioned)" >&2
        exit 1
      fi
      if (( _idx < 1 || _idx > ${array_dim[$2]} )); then
        echo "ICL241I ERROR TYPE 241 ENCOUNTERED (out of range)" >&2
        exit 1
      fi
      push "${array_data[${2}:${_idx}]:-0}"
      ;;
    READOUT_ARR)
      # Turing Text Model: per element, ttm_out_pos = (ttm_out_pos -
      # element) mod 256. Emit char = bit-reversal of ttm_out_pos.
      local _arr="$2"
      if [[ -z "${array_dims[$_arr]:-}" ]]; then
        echo "ICL241I undimensioned array in READ OUT" >&2
        exit 1
      fi
      # Total elements = product of all dim sizes; iterate flat
      # indices 0..total-1.
      local -a _ddl
      _ddl=(${=array_dims[$_arr]})
      local _total=1 _di=0
      for _di in "${_ddl[@]}"; do _total=$(( _total * _di )); done
      local _i=0
      for (( _i=0; _i<_total; _i++ )); do
        local _el=${array_data[${_arr}:${_i}]:-0}
        ttm_out_pos=$(( (ttm_out_pos - _el + 256) & 0xFF ))
        # Reverse 8 bits.
        local _b=$ttm_out_pos
        local _r=0 _bi=0
        for (( _bi=0; _bi<8; _bi++ )); do
          _r=$(( (_r << 1) | (_b & 1) ))
          _b=$(( _b >> 1 ))
        done
        # Emit byte _r as a single character via zsh's [#16] num
        # conversion + parameter expansion #...# .
        printf "\\x$(printf '%02x' $_r)"
      done
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
