#!/bin/zsh
# intercalc.sh - INTERCAL compiler bootstrap for macOS arm64
# Phase 1: reads .i from stdin, writes native Mach-O binary to stdout
# Usage: intercalc.sh < program.i > binary && chmod +x binary

setopt NO_ERR_EXIT
setopt PIPE_FAIL

# ============================================================
# SECTION 1: Global state
# ============================================================

asm=""
TMPBIN=$(mktemp /tmp/intercalc.XXXXXX)
trap "rm -f $TMPBIN" EXIT

typeset -a stmt_label stmt_polite stmt_negated stmt_prob stmt_type stmt_body
typeset -a stmt_next_target stmt_cf_target
typeset -A label_to_stmt come_from_target
stmt_count=0

typeset -A used_spot used_twospot used_tail used_hybrid

typeset -a expr_type expr_val expr_left expr_right expr_child expr_width
expr_next_id=0

parse_text=""
parse_pos=0
parse_result=0

needs_syslib=0

unique_id=0

SOURCE=""

# ============================================================
# SECTION 2: Utility functions
# ============================================================

emit() { asm+="$1"$'\n' }

die_compile() {
  local code=$1
  local msg=$2
  echo "ICL${code}I ${msg}" >&2
  exit 1
}

next_uid() {
  (( unique_id++ )) || true
  REPLY=$unique_id
}

# ============================================================
# SECTION 3: Lexer / Tokenizer
# ============================================================

read_source() {
  local raw
  raw=$(cat)
  raw=${raw//$'\n'/ }
  raw=${raw//$'\t'/ }
  raw=${raw//$'\r'/ }
  SOURCE=${(U)raw}
}

tokenize() {
  local text="$SOURCE"

  # Collapse multiple spaces into one
  while [[ "$text" == *"  "* ]]; do
    text="${text//  / }"
  done
  text="${text## }"
  text="${text%% }"

  # Strategy: use sed to insert markers before statement starts
  # Statement start = optional (digits) then DO/PLEASE/PLEASE DO
  # PLEASE DO is one keyword (polite); plain DO is another

  # Replace PLEASE DO (as one keyword) with a unique marker first
  text="${text//PLEASE DO/PLSDO}"

  # Now insert \x01 before each statement start:
  # Matches: (N) PLSDO, (N) PLEASE, (N) DO, PLSDO, PLEASE, DO
  # at word boundaries
  local result=""
  local -a words
  words=(${=text})  # split by whitespace

  local i=1
  local nwords=${#words[@]}
  while (( i <= nwords )); do
    local w="${words[$i]}"

    # Check if this word starts a new statement
    local is_start=0
    local label=""

    # Check for (N) label prefix
    # Only treat as label if not preceded by FROM (ABSTAIN FROM (N))
    # or REINSTATE (N) or other body keywords
    if [[ "$w" =~ '^\([0-9]+\)$' ]]; then
      local prev_word=""
      if (( i > 1 )); then prev_word="${words[$((i-1))]}"; fi
      # (N) is a label only if preceded by nothing meaningful (start or previous stmt end)
      # Not a label if preceded by FROM, NEXT, or statement body words
      if [[ "$prev_word" != "FROM" && "$prev_word" != "REINSTATE" ]]; then
        if (( i + 1 <= nwords )); then
          local nw="${words[$((i+1))]}"
          if [[ "$nw" == "DO" || "$nw" == "PLEASE" || "$nw" == "PLSDO" ]]; then
            label="$w"
            (( i++ ))
            w="${words[$i]}"
            is_start=1
          fi
        fi
      fi
    fi

    if [[ "$w" == "DO" || "$w" == "PLEASE" || "$w" == "PLSDO" ]]; then
      is_start=1
    fi

    if (( is_start )); then
      result+=$'\x01'
      if [[ -n "$label" ]]; then
        result+="${label} "
      fi
    fi

    result+="${w} "
    (( i++ ))
  done

  # Split on \x01 using IFS
  local -a parts
  local OLD_IFS="$IFS"
  IFS=$'\x01'
  parts=(${=result})
  IFS="$OLD_IFS"

  stmt_count=0
  for part in "${parts[@]}"; do
    # Trim leading/trailing whitespace
    part="${part## }"
    part="${part%% }"
    [[ -z "$part" ]] && continue

    (( stmt_count++ )) || true
    local idx=$stmt_count

    # Parse label
    stmt_label[$idx]=""
    local body="$part"
    if [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]*(.*)$' ]]; then
      stmt_label[$idx]="${match[1]}"
      body="${match[2]}"
    fi

    # Parse identifier (PLSDO, PLEASE, DO)
    stmt_polite[$idx]=0
    if [[ "$body" =~ '^PLSDO[[:space:]]*(.*)$' ]]; then
      stmt_polite[$idx]=1
      body="${match[1]}"
    elif [[ "$body" =~ '^PLEASE[[:space:]]*(.*)$' ]]; then
      stmt_polite[$idx]=1
      body="${match[1]}"
    elif [[ "$body" =~ '^DO[[:space:]]*(.*)$' ]]; then
      stmt_polite[$idx]=0
      body="${match[1]}"
    fi

    # Parse negation
    stmt_negated[$idx]=0
    if [[ "$body" =~ "^NOT[[:space:]]+(.*)\$" ]]; then
      stmt_negated[$idx]=1
      body="${match[1]}"
    elif [[ "$body" =~ "^N'T[[:space:]]+(.*)\$" ]]; then
      stmt_negated[$idx]=1
      body="${match[1]}"
    fi

    # Parse probability
    stmt_prob[$idx]=100
    if [[ "$body" =~ '^%([0-9]+)[[:space:]]*(.*)$' ]]; then
      stmt_prob[$idx]="${match[1]}"
      body="${match[2]}"
    fi

    # Trim body
    body="${body## }"
    body="${body%% }"
    stmt_body[$idx]="$body"

    # Classify statement
    classify_statement $idx
  done
}

classify_statement() {
  local idx=$1
  local body="${stmt_body[$idx]}"

  stmt_next_target[$idx]=""
  stmt_cf_target[$idx]=""

  if [[ "$body" == "GIVE UP" ]]; then
    stmt_type[$idx]="GIVE_UP"
  elif [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]*NEXT$' ]]; then
    stmt_type[$idx]="NEXT"
    stmt_next_target[$idx]="${match[1]}"
  elif [[ "$body" =~ '^RESUME[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="RESUME"
  elif [[ "$body" =~ '^FORGET[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="FORGET"
  elif [[ "$body" =~ '^COME[[:space:]]+FROM[[:space:]]+\(([0-9]+)\)$' ]]; then
    stmt_type[$idx]="COME_FROM"
    stmt_cf_target[$idx]="${match[1]}"
  elif [[ "$body" =~ '^READ[[:space:]]+OUT[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="READ_OUT"
  elif [[ "$body" =~ '^WRITE[[:space:]]+IN[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="WRITE_IN"
  elif [[ "$body" =~ '^ABSTAIN[[:space:]]+FROM[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="ABSTAIN"
  elif [[ "$body" =~ '^REINSTATE[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="REINSTATE"
  elif [[ "$body" =~ '^IGNORE[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="IGNORE"
  elif [[ "$body" =~ '^REMEMBER[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="REMEMBER"
  elif [[ "$body" =~ '^STASH[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="STASH"
  elif [[ "$body" =~ '^RETRIEVE[[:space:]]+(.+)$' ]]; then
    stmt_type[$idx]="RETRIEVE"
  elif [[ "$body" == *'<-'* ]]; then
    # Assignment or array dim
    local target="${body%%<-*}"
    target="${target## }"
    target="${target%% }"
    # Check if target is bare array (no SUB) -> dimension
    if [[ "$target" =~ '^[,;][0-9]+$' ]] && [[ "$body" != *'SUB'* ]]; then
      stmt_type[$idx]="ARRAY_DIM"
    else
      stmt_type[$idx]="ASSIGN"
    fi
  else
    stmt_type[$idx]="UNKNOWN"
  fi

  # Scan for variable references
  scan_variables "$body"
}

scan_variables() {
  local text="$1"
  local i=1
  local len=${#text}
  while (( i <= len )); do
    local ch="${text[$i]}"
    if [[ "$ch" == "." || "$ch" == ":" || "$ch" == "," || "$ch" == ";" ]]; then
      # Check if followed by digit
      if (( i + 1 <= len )) && [[ "${text[$((i+1))]}" =~ '[0-9]' ]]; then
        local num=""
        local j=$((i + 1))
        while (( j <= len )) && [[ "${text[$j]}" =~ '[0-9]' ]]; do
          num+="${text[$j]}"
          (( j++ ))
        done
        case "$ch" in
          .) used_spot[$num]=1 ;;
          :) used_twospot[$num]=1 ;;
          ,) used_tail[$num]=1 ;;
          \;) used_hybrid[$num]=1 ;;
        esac
        i=$j
        continue
      fi
    fi
    (( i++ ))
  done
}

# ============================================================
# SECTION 4: Semantic analysis
# ============================================================

check_politeness() {
  if (( stmt_count < 5 )); then return; fi
  local polite=0
  local i
  for (( i=1; i<=stmt_count; i++ )); do
    if (( stmt_polite[$i] )); then
      (( polite++ )) || true
    fi
  done
  if (( polite * 5 < stmt_count )); then
    die_compile "079" "PROGRAMMER IS INSUFFICIENTLY POLITE"
  fi
  if (( polite * 3 > stmt_count )); then
    die_compile "099" "PROGRAMMER IS OVERLY POLITE"
  fi
}

check_labels() {
  local i
  for (( i=1; i<=stmt_count; i++ )); do
    local lbl="${stmt_label[$i]}"
    [[ -z "$lbl" ]] && continue
    if (( lbl < 1 || lbl > 65535 )); then
      die_compile "197" "LABEL VALUE OUTSIDE PERMITTED RANGE"
    fi
    if [[ -n "${label_to_stmt[$lbl]:-}" ]]; then
      die_compile "182" "DUPLICATE LINE LABEL DETECTED"
    fi
    label_to_stmt[$lbl]=$i
  done
}

resolve_come_from() {
  local i
  for (( i=1; i<=stmt_count; i++ )); do
    if [[ "${stmt_type[$i]}" == "COME_FROM" ]]; then
      local target="${stmt_cf_target[$i]}"
      if [[ -n "${come_from_target[$target]:-}" ]]; then
        die_compile "555" "MULTIPLE COME FROM TARGETING SAME LABEL"
      fi
      come_from_target[$target]=$i
    fi
  done
}

detect_syslib() {
  local i
  for (( i=1; i<=stmt_count; i++ )); do
    if [[ "${stmt_type[$i]}" == "NEXT" ]]; then
      local target="${stmt_next_target[$i]}"
      if (( target >= 1000 && target <= 1999 )); then
        needs_syslib=1
        # Register syslib labels
        label_to_stmt[$target]="syslib_${target}"
      fi
    fi
  done

  if (( needs_syslib )); then
    # Ensure syslib variables exist
    used_spot[1]=1; used_spot[2]=1; used_spot[3]=1; used_spot[4]=1; used_spot[5]=1
    used_twospot[1]=1; used_twospot[2]=1; used_twospot[3]=1; used_twospot[4]=1
  fi
}

# ============================================================
# SECTION 5: Expression parser
# ============================================================

expr_new() {
  (( expr_next_id++ )) || true
  parse_result=$expr_next_id
}

skip_spaces() {
  local len=${#parse_text}
  while (( parse_pos < len )) && [[ "${parse_text[$((parse_pos+1))]}" == " " ]]; do
    (( parse_pos++ ))
  done
}

peek_char() {
  if (( parse_pos < ${#parse_text} )); then
    REPLY="${parse_text[$((parse_pos+1))]}"
  else
    REPLY=""
  fi
}

next_char() {
  peek_char
  if [[ -n "$REPLY" ]]; then
    (( parse_pos++ ))
  fi
}

parse_number() {
  local num=""
  while (( parse_pos < ${#parse_text} )); do
    local ch="${parse_text[$((parse_pos+1))]}"
    if [[ "$ch" =~ '[0-9]' ]]; then
      num+="$ch"
      (( parse_pos++ ))
    else
      break
    fi
  done
  REPLY=$num
}

# parse_expr grouping_char
# Sets parse_result to node id, updates parse_pos
parse_expr() {
  local group_char="${1:-}"
  skip_spaces

  if (( parse_pos >= ${#parse_text} )); then
    return 1
  fi

  peek_char
  local ch="$REPLY"

  # Constant #N
  if [[ "$ch" == "#" ]]; then
    (( parse_pos++ ))
    parse_number
    local val=$REPLY
    expr_new
    local id=$parse_result
    expr_type[$id]="CONST"
    expr_val[$id]=$val
    expr_width[$id]=16
    return 0
  fi

  # Unary operators: &, V, ?
  if [[ "$ch" == "&" || "$ch" == "V" || "$ch" == "?" ]]; then
    local op="$ch"
    (( parse_pos++ ))
    parse_expr "$group_char"
    local child=$parse_result
    expr_new
    local id=$parse_result
    case "$op" in
      '&') expr_type[$id]="OP_AND" ;;
      V)   expr_type[$id]="OP_OR" ;;
      '?') expr_type[$id]="OP_XOR" ;;
    esac
    expr_child[$id]=$child
    expr_width[$id]=${expr_width[$child]}
    return 0
  fi

  # Variable: .N, :N
  if [[ "$ch" == "." || "$ch" == ":" ]]; then
    local prefix="$ch"
    (( parse_pos++ ))
    parse_number
    local num=$REPLY
    expr_new
    local id=$parse_result
    if [[ "$prefix" == "." ]]; then
      expr_type[$id]="VAR_SPOT"
      expr_width[$id]=16
    else
      expr_type[$id]="VAR_TWOSPOT"
      expr_width[$id]=32
    fi
    expr_val[$id]=$num
    return 0
  fi

  # Array ref: ,N SUB or ;N SUB
  if [[ "$ch" == "," || "$ch" == ";" ]]; then
    local arr_prefix="$ch"
    (( parse_pos++ ))
    parse_number
    local arr_num=$REPLY

    # Check for SUB
    skip_spaces
    local saved_pos=$parse_pos
    # Try to read "SUB"
    if (( parse_pos + 3 <= ${#parse_text} )) && [[ "${parse_text[$((parse_pos+1)),$((parse_pos+3))]}" == "SUB" ]]; then
      parse_pos=$((parse_pos + 3))
      # Parse subscript expressions (may be multiple SUB)
      local -a subs
      subs=()
      while true; do
        skip_spaces
        parse_expr "$group_char"
        subs+=($parse_result)
        skip_spaces
        # Check for another SUB
        if (( parse_pos + 3 <= ${#parse_text} )) && [[ "${parse_text[$((parse_pos+1)),$((parse_pos+3))]}" == "SUB" ]]; then
          parse_pos=$((parse_pos + 3))
        else
          break
        fi
      done

      expr_new
      local id=$parse_result
      if [[ "$arr_prefix" == "," ]]; then
        expr_type[$id]="ARRAY_TAIL_REF"
        expr_width[$id]=16
      else
        expr_type[$id]="ARRAY_HYBRID_REF"
        expr_width[$id]=32
      fi
      expr_val[$id]=$arr_num
      # Store subscript count and first sub in left, rest we handle specially
      expr_left[$id]=${#subs[@]}  # number of subscripts
      expr_right[$id]="${subs[*]}"  # space-separated list of sub node ids
      return 0
    else
      # No SUB, this is just an array variable reference (for READ OUT)
      parse_pos=$saved_pos
      expr_new
      local id=$parse_result
      if [[ "$arr_prefix" == "," ]]; then
        expr_type[$id]="ARRAY_TAIL"
        expr_width[$id]=16
      else
        expr_type[$id]="ARRAY_HYBRID"
        expr_width[$id]=32
      fi
      expr_val[$id]=$arr_num
      return 0
    fi
  fi

  # Grouped expression: ' or "
  if [[ "$ch" == "'" || "$ch" == '"' ]]; then
    local open="$ch"
    (( parse_pos++ ))

    # Determine inner grouping char
    local inner_group
    if [[ "$open" == "'" ]]; then
      inner_group='"'
    else
      inner_group="'"
    fi

    # Parse first operand
    parse_expr "$inner_group"
    local left=$parse_result

    skip_spaces
    peek_char
    local next="$REPLY"

    # Check for binary operator
    if [[ "$next" == '$' || "$next" == '~' ]]; then
      local binop="$next"
      (( parse_pos++ ))
      skip_spaces
      parse_expr "$inner_group"
      local right=$parse_result

      skip_spaces
      # Expect closing quote
      peek_char
      if [[ "$REPLY" == "$open" ]]; then
        (( parse_pos++ ))
      fi

      expr_new
      local id=$parse_result
      if [[ "$binop" == '$' ]]; then
        expr_type[$id]="OP_MINGLE"
        expr_width[$id]=32
      else
        expr_type[$id]="OP_SELECT"
        expr_width[$id]=32
      fi
      expr_left[$id]=$left
      expr_right[$id]=$right
      return 0
    fi

    # Just a grouping (no binary op) - close and return the inner expr
    if [[ "$next" == "$open" ]]; then
      (( parse_pos++ ))
    fi
    # parse_result is already set to left
    parse_result=$left
    return 0
  fi

  # Unknown
  return 1
}

# ============================================================
# SECTION 6: Expression codegen
# ============================================================

codegen_expr() {
  local id=$1
  local type="${expr_type[$id]}"

  case "$type" in
    CONST)
      local val=${expr_val[$id]}
      if (( val <= 65535 )); then
        emit "  mov w0, #${val}"
      else
        emit "  movz w0, #$((val & 0xFFFF))"
        emit "  movk w0, #$((val >> 16)), lsl #16"
      fi
      ;;
    VAR_SPOT)
      local num=${expr_val[$id]}
      emit "  adrp x1, _spot_${num}@PAGE"
      emit "  add x1, x1, _spot_${num}@PAGEOFF"
      emit "  ldr w0, [x1]"
      ;;
    VAR_TWOSPOT)
      local num=${expr_val[$id]}
      emit "  adrp x1, _twospot_${num}@PAGE"
      emit "  add x1, x1, _twospot_${num}@PAGEOFF"
      emit "  ldr w0, [x1]"
      ;;
    ARRAY_TAIL_REF|ARRAY_HYBRID_REF)
      codegen_array_ref $id
      ;;
    ARRAY_TAIL|ARRAY_HYBRID)
      # Bare array reference (just load pointer, used for READ OUT)
      # This shouldn't appear in expression context normally
      emit "  mov w0, #0"
      ;;
    OP_MINGLE)
      local left=${expr_left[$id]}
      local right=${expr_right[$id]}
      codegen_expr $left
      emit "  stp w0, wzr, [sp, #-16]!"
      codegen_expr $right
      emit "  mov w1, w0"
      emit "  ldp w0, wzr, [sp], #16"
      emit "  bl _rt_mingle"
      ;;
    OP_SELECT)
      local left=${expr_left[$id]}
      local right=${expr_right[$id]}
      codegen_expr $left
      emit "  str x0, [sp, #-16]!"
      codegen_expr $right
      emit "  mov x1, x0"
      emit "  ldr x0, [sp], #16"
      local w=${expr_width[${expr_left[$id]}]}
      if (( w == 32 )); then
        emit "  mov w2, #32"
      else
        emit "  mov w2, #16"
      fi
      emit "  bl _rt_select"
      ;;
    OP_AND|OP_OR|OP_XOR)
      local child=${expr_child[$id]}
      codegen_expr $child
      local w=${expr_width[$id]}
      case "$type" in
        OP_AND)
          if (( w == 32 )); then emit "  bl _rt_unary_and_32"
          else emit "  bl _rt_unary_and_16"; fi ;;
        OP_OR)
          if (( w == 32 )); then emit "  bl _rt_unary_or_32"
          else emit "  bl _rt_unary_or_16"; fi ;;
        OP_XOR)
          if (( w == 32 )); then emit "  bl _rt_unary_xor_32"
          else emit "  bl _rt_unary_xor_16"; fi ;;
      esac
      ;;
  esac
}

codegen_array_ref() {
  local id=$1
  local type="${expr_type[$id]}"
  local arr_num=${expr_val[$id]}
  local nsubs=${expr_left[$id]}
  local sub_ids=(${=expr_right[$id]})

  local prefix
  local elem_size
  if [[ "$type" == "ARRAY_TAIL_REF" ]]; then
    prefix="tail"
    elem_size=2
  else
    prefix="hybrid"
    elem_size=4
  fi

  # For 1D case (common): index = sub1 - 1
  if (( nsubs == 1 )); then
    codegen_expr ${sub_ids[1]}
    emit "  sub w0, w0, #1"
    # Bounds check
    next_uid; local uid=$REPLY
    emit "  adrp x1, _${prefix}_${arr_num}_dims@PAGE"
    emit "  add x1, x1, _${prefix}_${arr_num}_dims@PAGEOFF"
    emit "  ldr w2, [x1]"
    emit "  cmp w0, w2"
    emit "  b.hs _rt_error_E241"
    # Load element
    emit "  adrp x1, _${prefix}_${arr_num}_ptr@PAGE"
    emit "  add x1, x1, _${prefix}_${arr_num}_ptr@PAGEOFF"
    emit "  ldr x1, [x1]"
    if (( elem_size == 2 )); then
      emit "  ldrh w0, [x1, x0, lsl #1]"
    else
      emit "  ldr w0, [x1, x0, lsl #2]"
    fi
  else
    # Multi-dimensional: compute linear index
    # Save subscripts on stack, then compute index
    # For simplicity in bootstrap, compute iteratively
    local s
    for s in "${sub_ids[@]}"; do
      codegen_expr $s
      emit "  str w0, [sp, #-16]!"
    done
    # Now compute linear index: ((s1-1)*d2 + (s2-1))*d3 + ... + (sn-1)
    emit "  mov w0, #0"  # accumulated index
    local j
    for (( j=1; j<=nsubs; j++ )); do
      if (( j > 1 )); then
        # Multiply accumulated by dim[j]
        emit "  adrp x1, _${prefix}_${arr_num}_dims@PAGE"
        emit "  add x1, x1, _${prefix}_${arr_num}_dims@PAGEOFF"
        emit "  ldr w2, [x1, #$(( (j-1) * 4 ))]"
        emit "  mul w0, w0, w2"
      fi
      # Add (sub[j] - 1)
      local stack_off=$(( (nsubs - j) * 16 ))
      emit "  ldr w3, [sp, #${stack_off}]"
      emit "  sub w3, w3, #1"
      emit "  add w0, w0, w3"
    done
    # Clean stack
    emit "  add sp, sp, #$(( nsubs * 16 ))"
    # Load element
    emit "  adrp x1, _${prefix}_${arr_num}_ptr@PAGE"
    emit "  add x1, x1, _${prefix}_${arr_num}_ptr@PAGEOFF"
    emit "  ldr x1, [x1]"
    if (( elem_size == 2 )); then
      emit "  ldrh w0, [x1, x0, lsl #1]"
    else
      emit "  ldr w0, [x1, x0, lsl #2]"
    fi
  fi
}

# ============================================================
# SECTION 7: Statement codegen
# ============================================================

codegen_program() {
  emit ".section __TEXT,__text"
  emit ".global _main"
  emit ".align 2"
  emit ""
  emit "_main:"
  emit "  stp x29, x30, [sp, #-16]!"
  emit "  mov x29, sp"
  emit ""

  local i
  for (( i=1; i<=stmt_count; i++ )); do
    codegen_statement $i
  done

  emit "  b _rt_error_E633"
  emit ""

  emit_runtime
  emit_data
}

codegen_statement() {
  local i=$1
  emit ""
  emit "_stmt_${i}:  // ${stmt_type[$i]}"

  # Abstain check
  emit "  adrp x0, _stmt_flags@PAGE"
  emit "  add x0, x0, _stmt_flags@PAGEOFF"
  emit "  ldrb w1, [x0, #$((i-1))]"
  emit "  tbnz w1, #0, _stmt_${i}_end"

  # Probability check
  if (( stmt_prob[$i] < 100 )); then
    codegen_probability $i
  fi

  case "${stmt_type[$i]}" in
    GIVE_UP)    codegen_give_up ;;
    READ_OUT)   codegen_read_out $i ;;
    WRITE_IN)   codegen_write_in $i ;;
    ASSIGN)     codegen_assign $i ;;
    ARRAY_DIM)  codegen_array_dim $i ;;
    NEXT)       codegen_next $i ;;
    RESUME)     codegen_resume $i ;;
    FORGET)     codegen_forget $i ;;
    COME_FROM)  ;; # handled at target
    ABSTAIN)    codegen_abstain $i ;;
    REINSTATE)  codegen_reinstate $i ;;
    IGNORE)     codegen_ignore $i ;;
    REMEMBER)   codegen_remember $i ;;
    STASH)      codegen_stash $i ;;
    RETRIEVE)   codegen_retrieve $i ;;
    UNKNOWN)    emit "  b _rt_error_E000" ;;
  esac

  emit "_stmt_${i}_end:"

  # COME FROM redirect
  local lbl="${stmt_label[$i]}"
  if [[ -n "$lbl" ]] && [[ -n "${come_from_target[$lbl]:-}" ]]; then
    local cf_stmt=${come_from_target[$lbl]}
    emit "  adrp x0, _stmt_flags@PAGE"
    emit "  add x0, x0, _stmt_flags@PAGEOFF"
    emit "  ldrb w1, [x0, #$((cf_stmt-1))]"
    emit "  tbnz w1, #0, _stmt_${i}_nocf"
    emit "  b _stmt_${cf_stmt}"
    emit "_stmt_${i}_nocf:"
  fi
}

codegen_give_up() {
  emit "  mov x0, #0"
  emit "  mov x16, #1"
  emit "  svc #0x80"
}

codegen_probability() {
  local i=$1
  emit "  sub sp, sp, #16"
  emit "  mov x0, sp"
  emit "  mov x1, #4"
  emit "  mov x16, #500"
  emit "  svc #0x80"
  emit "  ldr w0, [sp]"
  emit "  add sp, sp, #16"
  emit "  mov w1, #100"
  emit "  udiv w2, w0, w1"
  emit "  msub w0, w2, w1, w0"
  emit "  cmp w0, #${stmt_prob[$i]}"
  emit "  b.ge _stmt_${i}_end"
}

# Parse a variable list from body (after keyword)
# Returns items in var_list array
parse_var_list() {
  local text="$1"
  var_list=()
  # Simple split: items are separated by spaces at the top level
  # But we need to handle expressions in grouping chars
  local current=""
  local depth=0
  local i=1
  local len=${#text}
  while (( i <= len )); do
    local ch="${text[$i]}"
    if [[ "$ch" == "'" || "$ch" == '"' ]]; then
      (( depth++ )) || true
      current+="$ch"
    elif (( depth > 0 )); then
      current+="$ch"
      if [[ "$ch" == "'" || "$ch" == '"' ]]; then
        (( depth-- )) || true
      fi
    elif [[ "$ch" == " " ]]; then
      if [[ -n "$current" ]]; then
        # Check if this is a SUB continuation
        local rest="${text[$((i+1)),$len]}"
        rest="${rest## }"
        if [[ "$rest" == SUB* ]]; then
          current+=" "
        else
          var_list+=("$current")
          current=""
        fi
      fi
    else
      current+="$ch"
    fi
    (( i++ ))
  done
  if [[ -n "$current" ]]; then
    var_list+=("$current")
  fi
}

codegen_read_out() {
  local i=$1
  local body="${stmt_body[$i]}"
  local items="${body#READ OUT }"
  items="${items## }"

  # Parse variable list
  local -a var_list
  parse_var_list "$items"

  for item in "${var_list[@]}"; do
    item="${item## }"
    item="${item%% }"
    [[ -z "$item" ]] && continue

    # Array variable (bare, for TTM output)
    if [[ "$item" =~ '^,[0-9]+$' ]]; then
      local arr_num="${item#,}"
      emit "  adrp x0, _tail_${arr_num}_ptr@PAGE"
      emit "  add x0, x0, _tail_${arr_num}_ptr@PAGEOFF"
      emit "  ldr x0, [x0]"
      emit "  adrp x1, _tail_${arr_num}_dims@PAGE"
      emit "  add x1, x1, _tail_${arr_num}_dims@PAGEOFF"
      emit "  ldr w1, [x1]"
      emit "  mov w2, #2"
      emit "  bl _rt_read_out_array"
      continue
    fi
    if [[ "$item" =~ '^;[0-9]+$' ]]; then
      local arr_num="${item#;}"
      emit "  adrp x0, _hybrid_${arr_num}_ptr@PAGE"
      emit "  add x0, x0, _hybrid_${arr_num}_ptr@PAGEOFF"
      emit "  ldr x0, [x0]"
      emit "  adrp x1, _hybrid_${arr_num}_dims@PAGE"
      emit "  add x1, x1, _hybrid_${arr_num}_dims@PAGEOFF"
      emit "  ldr w1, [x1]"
      emit "  mov w2, #4"
      emit "  bl _rt_read_out_array"
      continue
    fi

    # Parse as expression
    parse_text="$item"
    parse_pos=0
    if parse_expr ""; then
      codegen_expr $parse_result
      emit "  bl _rt_write_roman"
    fi
  done
}

codegen_write_in() {
  local i=$1
  local body="${stmt_body[$i]}"
  local items="${body#WRITE IN }"
  items="${items## }"

  local -a var_list
  parse_var_list "$items"

  for item in "${var_list[@]}"; do
    item="${item## }"
    item="${item%% }"
    [[ -z "$item" ]] && continue

    # Array variable (TTM input)
    if [[ "$item" =~ '^,[0-9]+$' ]]; then
      local arr_num="${item#,}"
      emit "  adrp x0, _tail_${arr_num}_ptr@PAGE"
      emit "  add x0, x0, _tail_${arr_num}_ptr@PAGEOFF"
      emit "  ldr x0, [x0]"
      emit "  adrp x1, _tail_${arr_num}_dims@PAGE"
      emit "  add x1, x1, _tail_${arr_num}_dims@PAGEOFF"
      emit "  ldr w1, [x1]"
      emit "  mov w2, #2"
      emit "  bl _rt_write_in_array"
      continue
    fi
    if [[ "$item" =~ '^;[0-9]+$' ]]; then
      local arr_num="${item#;}"
      emit "  adrp x0, _hybrid_${arr_num}_ptr@PAGE"
      emit "  add x0, x0, _hybrid_${arr_num}_ptr@PAGEOFF"
      emit "  ldr x0, [x0]"
      emit "  adrp x1, _hybrid_${arr_num}_dims@PAGE"
      emit "  add x1, x1, _hybrid_${arr_num}_dims@PAGEOFF"
      emit "  ldr w1, [x1]"
      emit "  mov w2, #4"
      emit "  bl _rt_write_in_array"
      continue
    fi

    # Scalar variable
    if [[ "$item" =~ '^\.[0-9]+$' ]]; then
      local vnum="${item#.}"
      emit "  bl _rt_write_in_scalar"
      # Check 16-bit overflow
      emit "  mov w1, #65535"
      emit "  cmp w0, w1"
      emit "  b.hi _rt_error_E275"
      emit "  adrp x1, _spot_${vnum}_ign@PAGE"
      emit "  add x1, x1, _spot_${vnum}_ign@PAGEOFF"
      emit "  ldrb w2, [x1]"
      next_uid; local uid=$REPLY
      emit "  cbnz w2, .Lwi_skip_${uid}"
      emit "  adrp x1, _spot_${vnum}@PAGE"
      emit "  add x1, x1, _spot_${vnum}@PAGEOFF"
      emit "  str w0, [x1]"
      emit ".Lwi_skip_${uid}:"
      continue
    fi
    if [[ "$item" =~ '^:[0-9]+$' ]]; then
      local vnum="${item#:}"
      emit "  bl _rt_write_in_scalar"
      emit "  adrp x1, _twospot_${vnum}_ign@PAGE"
      emit "  add x1, x1, _twospot_${vnum}_ign@PAGEOFF"
      emit "  ldrb w2, [x1]"
      next_uid; local uid=$REPLY
      emit "  cbnz w2, .Lwi_skip_${uid}"
      emit "  adrp x1, _twospot_${vnum}@PAGE"
      emit "  add x1, x1, _twospot_${vnum}@PAGEOFF"
      emit "  str w0, [x1]"
      emit ".Lwi_skip_${uid}:"
      continue
    fi
  done
}

codegen_assign() {
  local i=$1
  local body="${stmt_body[$i]}"
  local target="${body%%<-*}"
  local expr_str="${body#*<-}"
  target="${target## }"
  target="${target%% }"
  expr_str="${expr_str## }"

  # Array element assignment: target contains SUB
  if [[ "$target" == *SUB* ]]; then
    codegen_array_elem_assign $i "$target" "$expr_str"
    return
  fi

  parse_text="$expr_str"
  parse_pos=0
  parse_expr ""
  local node=$parse_result
  codegen_expr $node

  if [[ "$target" =~ '^\.[0-9]+$' ]]; then
    local vnum="${target#.}"
    emit "  mov w1, #65535"
    emit "  cmp w0, w1"
    emit "  b.hi _rt_error_E275"
    emit "  adrp x1, _spot_${vnum}_ign@PAGE"
    emit "  add x1, x1, _spot_${vnum}_ign@PAGEOFF"
    emit "  ldrb w2, [x1]"
    emit "  cbnz w2, _stmt_${i}_end"
    emit "  adrp x1, _spot_${vnum}@PAGE"
    emit "  add x1, x1, _spot_${vnum}@PAGEOFF"
    emit "  str w0, [x1]"
  elif [[ "$target" =~ '^:[0-9]+$' ]]; then
    local vnum="${target#:}"
    emit "  adrp x1, _twospot_${vnum}_ign@PAGE"
    emit "  add x1, x1, _twospot_${vnum}_ign@PAGEOFF"
    emit "  ldrb w2, [x1]"
    emit "  cbnz w2, _stmt_${i}_end"
    emit "  adrp x1, _twospot_${vnum}@PAGE"
    emit "  add x1, x1, _twospot_${vnum}@PAGEOFF"
    emit "  str w0, [x1]"
  fi
}

codegen_array_elem_assign() {
  local i=$1
  local target="$2"
  local expr_str="$3"

  # Parse target: ,N SUB expr SUB expr ...
  local arr_prefix="${target[1]}"
  local rest="${target[2,-1]}"
  # Extract array number (before SUB)
  local arr_part="${rest%% SUB*}"
  arr_part="${arr_part%% *}"
  local arr_num="$arr_part"
  # Extract subscripts text
  local sub_text="${rest#*SUB}"

  local prefix elem_size
  if [[ "$arr_prefix" == "," ]]; then
    prefix="tail"; elem_size=2
  else
    prefix="hybrid"; elem_size=4
  fi

  # Parse and evaluate expression first, save on stack
  parse_text="$expr_str"
  parse_pos=0
  parse_expr ""
  codegen_expr $parse_result
  emit "  str w0, [sp, #-16]!"  # save value

  # Parse subscripts
  # Split by SUB
  local -a sub_parts
  sub_parts=("${(@s:SUB:)sub_text}")

  local nsubs=${#sub_parts[@]}

  # Evaluate each subscript
  for sp_item in "${sub_parts[@]}"; do
    sp_item="${sp_item## }"
    sp_item="${sp_item%% }"
    [[ -z "$sp_item" ]] && continue
    parse_text="$sp_item"
    parse_pos=0
    parse_expr ""
    codegen_expr $parse_result
    emit "  str w0, [sp, #-16]!"
  done

  # Compute linear index for 1D case
  if (( nsubs == 1 )); then
    emit "  ldr w0, [sp], #16"  # subscript
    emit "  sub w0, w0, #1"     # 0-indexed
    # Bounds check
    emit "  adrp x1, _${prefix}_${arr_num}_dims@PAGE"
    emit "  add x1, x1, _${prefix}_${arr_num}_dims@PAGEOFF"
    emit "  ldr w2, [x1]"
    emit "  cmp w0, w2"
    emit "  b.hs _rt_error_E241"
  else
    # Multi-dim: compute linear index
    # Subscripts are on stack in reverse order (last pushed first)
    emit "  mov w0, #0"
    local j
    for (( j=1; j<=nsubs; j++ )); do
      if (( j > 1 )); then
        emit "  adrp x1, _${prefix}_${arr_num}_dims@PAGE"
        emit "  add x1, x1, _${prefix}_${arr_num}_dims@PAGEOFF"
        emit "  ldr w2, [x1, #$(( (j-1) * 4 ))]"
        emit "  mul w0, w0, w2"
      fi
      local stack_off=$(( (nsubs - j) * 16 ))
      emit "  ldr w3, [sp, #${stack_off}]"
      emit "  sub w3, w3, #1"
      emit "  add w0, w0, w3"
    done
    emit "  add sp, sp, #$(( nsubs * 16 ))"
  fi

  # Check ignore flag
  emit "  adrp x1, _${prefix}_${arr_num}_ign@PAGE"
  emit "  add x1, x1, _${prefix}_${arr_num}_ign@PAGEOFF"
  emit "  ldrb w2, [x1]"
  emit "  cbnz w2, _stmt_${i}_aeskip"

  # Store element
  emit "  adrp x1, _${prefix}_${arr_num}_ptr@PAGE"
  emit "  add x1, x1, _${prefix}_${arr_num}_ptr@PAGEOFF"
  emit "  ldr x1, [x1]"
  emit "  ldr w2, [sp], #16"  # value
  if (( elem_size == 2 )); then
    emit "  strh w2, [x1, x0, lsl #1]"
  else
    emit "  str w2, [x1, x0, lsl #2]"
  fi
  next_uid; local uid=$REPLY
  emit "  b _stmt_${i}_aedone"
  emit "_stmt_${i}_aeskip:"
  emit "  add sp, sp, #16"  # discard value
  emit "_stmt_${i}_aedone:"
}

codegen_array_dim() {
  local i=$1
  local body="${stmt_body[$i]}"
  local target="${body%%<-*}"
  local dims_str="${body#*<-}"
  target="${target## }"
  target="${target%% }"
  dims_str="${dims_str## }"

  local arr_prefix="${target[1]}"
  local arr_num="${target[2,-1]}"

  local prefix elem_size
  if [[ "$arr_prefix" == "," ]]; then
    prefix="tail"; elem_size=2
  else
    prefix="hybrid"; elem_size=4
  fi

  # Parse dimensions (split by BY)
  local -a dim_parts
  dim_parts=("${(@s:BY:)dims_str}")

  local ndims=${#dim_parts[@]}

  # Evaluate each dimension and save
  local total_expr="1"
  local d
  for d in "${dim_parts[@]}"; do
    d="${d## }"
    d="${d%% }"
    parse_text="$d"
    parse_pos=0
    parse_expr ""
    codegen_expr $parse_result
    emit "  str w0, [sp, #-16]!"
  done

  # Store dimensions and compute total size
  emit "  mov w10, #1"  # total elements
  local j
  for (( j=1; j<=ndims; j++ )); do
    local stack_off=$(( (ndims - j) * 16 ))
    emit "  ldr w11, [sp, #${stack_off}]"
    # Check dim > 0
    emit "  cbz w11, _rt_error_E240"
    # Store dimension
    emit "  adrp x12, _${prefix}_${arr_num}_dims@PAGE"
    emit "  add x12, x12, _${prefix}_${arr_num}_dims@PAGEOFF"
    emit "  str w11, [x12, #$(( (j-1) * 4 ))]"
    emit "  mul w10, w10, w11"
  done
  emit "  add sp, sp, #$(( ndims * 16 ))"

  # Store ndim
  emit "  adrp x12, _${prefix}_${arr_num}_ndim@PAGE"
  emit "  add x12, x12, _${prefix}_${arr_num}_ndim@PAGEOFF"
  emit "  mov w11, #${ndims}"
  emit "  str w11, [x12]"

  # Allocate memory: total * elem_size
  if (( elem_size == 2 )); then
    emit "  lsl x0, x10, #1"
  else
    emit "  lsl x0, x10, #2"
  fi
  emit "  bl _rt_mmap"

  # Store pointer
  emit "  adrp x12, _${prefix}_${arr_num}_ptr@PAGE"
  emit "  add x12, x12, _${prefix}_${arr_num}_ptr@PAGEOFF"
  emit "  str x0, [x12]"
}

codegen_next() {
  local i=$1
  local target_label="${stmt_next_target[$i]}"
  local target_ref="${label_to_stmt[$target_label]:-}"

  if [[ -z "$target_ref" ]]; then
    emit "  b _rt_error_E129"
    return
  fi

  # Check NEXT stack depth
  emit "  adrp x0, _next_sp@PAGE"
  emit "  add x0, x0, _next_sp@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  cmp w1, #79"
  emit "  b.ge _rt_error_E123"
  # Push return address
  emit "  adrp x2, _next_stack@PAGE"
  emit "  add x2, x2, _next_stack@PAGEOFF"
  emit "  adrp x3, _stmt_${i}_end@PAGE"
  emit "  add x3, x3, _stmt_${i}_end@PAGEOFF"
  emit "  str x3, [x2, x1, lsl #3]"
  emit "  add w1, w1, #1"
  emit "  str w1, [x0]"

  if [[ "$target_ref" == syslib_* ]]; then
    local syslib_num="${target_ref#syslib_}"
    emit "  b _rt_syslib_${syslib_num}"
  else
    emit "  b _stmt_${target_ref}"
  fi
}

codegen_resume() {
  local i=$1
  local body="${stmt_body[$i]}"
  local expr_str="${body#RESUME }"
  expr_str="${expr_str## }"

  parse_text="$expr_str"
  parse_pos=0
  parse_expr ""
  codegen_expr $parse_result

  emit "  cbz w0, _rt_error_E621"
  emit "  adrp x1, _next_sp@PAGE"
  emit "  add x1, x1, _next_sp@PAGEOFF"
  emit "  ldr w2, [x1]"
  emit "  subs w3, w2, w0"
  emit "  b.mi _rt_error_E632"
  emit "  str w3, [x1]"
  emit "  adrp x4, _next_stack@PAGE"
  emit "  add x4, x4, _next_stack@PAGEOFF"
  emit "  ldr x5, [x4, x3, lsl #3]"
  emit "  br x5"
}

codegen_forget() {
  local i=$1
  local body="${stmt_body[$i]}"
  local expr_str="${body#FORGET }"
  expr_str="${expr_str## }"

  parse_text="$expr_str"
  parse_pos=0
  parse_expr ""
  codegen_expr $parse_result

  emit "  adrp x1, _next_sp@PAGE"
  emit "  add x1, x1, _next_sp@PAGEOFF"
  emit "  ldr w2, [x1]"
  emit "  subs w2, w2, w0"
  emit "  csel w2, wzr, w2, mi"
  emit "  str w2, [x1]"
}

codegen_abstain() {
  local i=$1
  local body="${stmt_body[$i]}"
  local arg="${body#ABSTAIN FROM }"
  arg="${arg## }"

  # Check if it's a label reference
  if [[ "$arg" =~ '^\(([0-9]+)\)$' ]]; then
    local target_label="${match[1]}"
    local target_stmt="${label_to_stmt[$target_label]:-}"
    if [[ -z "$target_stmt" || "$target_stmt" == syslib_* ]]; then
      emit "  b _rt_error_E139"
      return
    fi
    emit "  adrp x0, _stmt_flags@PAGE"
    emit "  add x0, x0, _stmt_flags@PAGEOFF"
    emit "  mov w1, #1"
    emit "  strb w1, [x0, #$((target_stmt-1))]"
  else
    # Gerund list
    codegen_gerund_modify "$arg" 1
  fi
}

codegen_reinstate() {
  local i=$1
  local body="${stmt_body[$i]}"
  local arg="${body#REINSTATE }"
  arg="${arg## }"

  if [[ "$arg" =~ '^\(([0-9]+)\)$' ]]; then
    local target_label="${match[1]}"
    local target_stmt="${label_to_stmt[$target_label]:-}"
    if [[ -z "$target_stmt" || "$target_stmt" == syslib_* ]]; then
      emit "  b _rt_error_E139"
      return
    fi
    emit "  adrp x0, _stmt_flags@PAGE"
    emit "  add x0, x0, _stmt_flags@PAGEOFF"
    emit "  mov w1, #0"
    emit "  strb w1, [x0, #$((target_stmt-1))]"
  else
    codegen_gerund_modify "$arg" 0
  fi
}

codegen_gerund_modify() {
  local gerund_text="$1"
  local flag_value=$2

  # Map gerunds to statement types
  local -A gerund_map
  gerund_map[CALCULATING]="ASSIGN ARRAY_DIM"
  gerund_map[NEXTING]="NEXT"
  gerund_map[FORGETTING]="FORGET"
  gerund_map[RESUMING]="RESUME"
  gerund_map[STASHING]="STASH"
  gerund_map[RETRIEVING]="RETRIEVE"
  gerund_map[IGNORING]="IGNORE"
  gerund_map[REMEMBERING]="REMEMBER"
  gerund_map[ABSTAINING]="ABSTAIN"
  gerund_map[REINSTATING]="REINSTATE"

  # Multi-word gerunds
  local text="$gerund_text"
  text="${text/COMING FROM/COMINGFROM}"
  text="${text/READING OUT/READINGOUT}"
  text="${text/WRITING IN/WRITINGIN}"
  gerund_map[COMINGFROM]="COME_FROM"
  gerund_map[READINGOUT]="READ_OUT"
  gerund_map[WRITINGIN]="WRITE_IN"

  local -a gerunds
  gerunds=(${=text})

  emit "  adrp x0, _stmt_flags@PAGE"
  emit "  add x0, x0, _stmt_flags@PAGEOFF"
  emit "  mov w1, #${flag_value}"

  for g in "${gerunds[@]}"; do
    local types="${gerund_map[$g]:-}"
    [[ -z "$types" ]] && continue
    local j
    for (( j=1; j<=stmt_count; j++ )); do
      for t in ${=types}; do
        if [[ "${stmt_type[$j]}" == "$t" ]]; then
          emit "  strb w1, [x0, #$((j-1))]"
        fi
      done
    done
  done
}

codegen_ignore() {
  local i=$1
  local body="${stmt_body[$i]}"
  local items="${body#IGNORE }"

  local -a var_list
  parse_var_list "$items"

  for item in "${var_list[@]}"; do
    item="${item## }"
    item="${item%% }"
    if [[ "$item" =~ '^\.[0-9]+$' ]]; then
      local vnum="${item#.}"
      emit "  adrp x0, _spot_${vnum}_ign@PAGE"
      emit "  add x0, x0, _spot_${vnum}_ign@PAGEOFF"
      emit "  mov w1, #1"
      emit "  strb w1, [x0]"
    elif [[ "$item" =~ '^:[0-9]+$' ]]; then
      local vnum="${item#:}"
      emit "  adrp x0, _twospot_${vnum}_ign@PAGE"
      emit "  add x0, x0, _twospot_${vnum}_ign@PAGEOFF"
      emit "  mov w1, #1"
      emit "  strb w1, [x0]"
    elif [[ "$item" =~ '^,[0-9]+$' ]]; then
      local vnum="${item#,}"
      emit "  adrp x0, _tail_${vnum}_ign@PAGE"
      emit "  add x0, x0, _tail_${vnum}_ign@PAGEOFF"
      emit "  mov w1, #1"
      emit "  strb w1, [x0]"
    elif [[ "$item" =~ '^;[0-9]+$' ]]; then
      local vnum="${item#;}"
      emit "  adrp x0, _hybrid_${vnum}_ign@PAGE"
      emit "  add x0, x0, _hybrid_${vnum}_ign@PAGEOFF"
      emit "  mov w1, #1"
      emit "  strb w1, [x0]"
    fi
  done
}

codegen_remember() {
  local i=$1
  local body="${stmt_body[$i]}"
  local items="${body#REMEMBER }"

  local -a var_list
  parse_var_list "$items"

  for item in "${var_list[@]}"; do
    item="${item## }"
    item="${item%% }"
    if [[ "$item" =~ '^\.[0-9]+$' ]]; then
      local vnum="${item#.}"
      emit "  adrp x0, _spot_${vnum}_ign@PAGE"
      emit "  add x0, x0, _spot_${vnum}_ign@PAGEOFF"
      emit "  strb wzr, [x0]"
    elif [[ "$item" =~ '^:[0-9]+$' ]]; then
      local vnum="${item#:}"
      emit "  adrp x0, _twospot_${vnum}_ign@PAGE"
      emit "  add x0, x0, _twospot_${vnum}_ign@PAGEOFF"
      emit "  strb wzr, [x0]"
    elif [[ "$item" =~ '^,[0-9]+$' ]]; then
      local vnum="${item#,}"
      emit "  adrp x0, _tail_${vnum}_ign@PAGE"
      emit "  add x0, x0, _tail_${vnum}_ign@PAGEOFF"
      emit "  strb wzr, [x0]"
    elif [[ "$item" =~ '^;[0-9]+$' ]]; then
      local vnum="${item#;}"
      emit "  adrp x0, _hybrid_${vnum}_ign@PAGE"
      emit "  add x0, x0, _hybrid_${vnum}_ign@PAGEOFF"
      emit "  strb wzr, [x0]"
    fi
  done
}

codegen_stash() {
  local i=$1
  local body="${stmt_body[$i]}"
  local items="${body#STASH }"

  local -a var_list
  parse_var_list "$items"

  for item in "${var_list[@]}"; do
    item="${item## }"
    item="${item%% }"
    if [[ "$item" =~ '^\.[0-9]+$' ]]; then
      codegen_stash_var "spot" "${item#.}" $i
    elif [[ "$item" =~ '^:[0-9]+$' ]]; then
      codegen_stash_var "twospot" "${item#:}" $i
    fi
  done
}

codegen_stash_var() {
  local prefix=$1 num=$2 stmt_idx=$3
  next_uid; local uid=$REPLY

  emit "  adrp x0, _${prefix}_${num}_stash_ptr@PAGE"
  emit "  add x0, x0, _${prefix}_${num}_stash_ptr@PAGEOFF"
  emit "  ldr x1, [x0]"
  emit "  cbnz x1, .Lstash_ok_${uid}"
  # Allocate stash
  emit "  stp x0, x30, [sp, #-16]!"
  emit "  mov x0, #4096"
  emit "  bl _rt_mmap"
  emit "  ldp x2, x30, [sp], #16"
  emit "  str x0, [x2]"
  emit "  mov x1, x0"
  emit ".Lstash_ok_${uid}:"
  # Push value
  emit "  adrp x2, _${prefix}_${num}_stash_sp@PAGE"
  emit "  add x2, x2, _${prefix}_${num}_stash_sp@PAGEOFF"
  emit "  ldr w3, [x2]"
  emit "  adrp x4, _${prefix}_${num}@PAGE"
  emit "  add x4, x4, _${prefix}_${num}@PAGEOFF"
  emit "  ldr w5, [x4]"
  emit "  str w5, [x1, x3, lsl #2]"
  emit "  add w3, w3, #1"
  emit "  str w3, [x2]"
}

codegen_retrieve() {
  local i=$1
  local body="${stmt_body[$i]}"
  local items="${body#RETRIEVE }"

  local -a var_list
  parse_var_list "$items"

  for item in "${var_list[@]}"; do
    item="${item## }"
    item="${item%% }"
    if [[ "$item" =~ '^\.[0-9]+$' ]]; then
      codegen_retrieve_var "spot" "${item#.}" $i
    elif [[ "$item" =~ '^:[0-9]+$' ]]; then
      codegen_retrieve_var "twospot" "${item#:}" $i
    fi
  done
}

codegen_retrieve_var() {
  local prefix=$1 num=$2 stmt_idx=$3

  emit "  adrp x2, _${prefix}_${num}_stash_sp@PAGE"
  emit "  add x2, x2, _${prefix}_${num}_stash_sp@PAGEOFF"
  emit "  ldr w3, [x2]"
  emit "  cbz w3, _rt_error_E436"
  emit "  sub w3, w3, #1"
  emit "  str w3, [x2]"
  emit "  adrp x0, _${prefix}_${num}_stash_ptr@PAGE"
  emit "  add x0, x0, _${prefix}_${num}_stash_ptr@PAGEOFF"
  emit "  ldr x1, [x0]"
  emit "  ldr w5, [x1, x3, lsl #2]"
  emit "  adrp x4, _${prefix}_${num}@PAGE"
  emit "  add x4, x4, _${prefix}_${num}@PAGEOFF"
  emit "  str w5, [x4]"
}

# ============================================================
# SECTION 8: Runtime library (ARM64 assembly)
# ============================================================

emit_runtime() {
  emit ""
  emit "// ========== Runtime Library =========="
  emit ""

  # Mingle
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_mingle:
  mov x2, #0
  mov w3, #0
.Lmingle_loop:
  cmp w3, #16
  b.ge .Lmingle_done
  lsr w4, w1, w3
  and w4, w4, #1
  lsl w5, w3, #1
  lsl w4, w4, w5
  orr x2, x2, x4
  lsr w4, w0, w3
  and w4, w4, #1
  add w5, w5, #1
  lsl w4, w4, w5
  orr x2, x2, x4
  add w3, w3, #1
  b .Lmingle_loop
.Lmingle_done:
  mov x0, x2
  ret
RTASM

  emit ""

  # Select
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_select:
  mov x3, #0
  mov w4, #0
  mov w5, #0
.Lselect_loop:
  cmp w5, w2
  b.ge .Lselect_done
  lsr x6, x1, x5
  tbz x6, #0, .Lselect_next
  lsr x6, x0, x5
  and x6, x6, #1
  lsl x6, x6, x4
  orr x3, x3, x6
  add w4, w4, #1
.Lselect_next:
  add w5, w5, #1
  b .Lselect_loop
.Lselect_done:
  mov x0, x3
  ret
RTASM

  emit ""

  # Unary operators
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_unary_and_16:
  lsr w1, w0, #1
  lsl w2, w0, #15
  orr w1, w1, w2
  and w1, w1, #0xFFFF
  and w0, w0, w1
  and w0, w0, #0xFFFF
  ret

_rt_unary_or_16:
  lsr w1, w0, #1
  lsl w2, w0, #15
  orr w1, w1, w2
  and w1, w1, #0xFFFF
  orr w0, w0, w1
  and w0, w0, #0xFFFF
  ret

_rt_unary_xor_16:
  lsr w1, w0, #1
  lsl w2, w0, #15
  orr w1, w1, w2
  and w1, w1, #0xFFFF
  eor w0, w0, w1
  and w0, w0, #0xFFFF
  ret

_rt_unary_and_32:
  ror w1, w0, #1
  and w0, w0, w1
  ret

_rt_unary_or_32:
  ror w1, w0, #1
  orr w0, w0, w1
  ret

_rt_unary_xor_32:
  ror w1, w0, #1
  eor w0, w0, w1
  ret
RTASM

  emit ""

  # Roman numeral output
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_write_roman:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  mov w19, w0
  cbz w19, .Lroman_done
  adrp x20, _rtable@PAGE
  add x20, x20, _rtable@PAGEOFF
.Lroman_loop:
  ldr w0, [x20]
  cbz w0, .Lroman_done
  cmp w19, w0
  b.lo .Lroman_next
  sub w19, w19, w0
  ldr w1, [x20, #4]
  adrp x2, _rstrings@PAGE
  add x2, x2, _rstrings@PAGEOFF
  add x1, x2, w1, uxtw
  mov x3, x1
  mov w4, #0
.Lroman_slen:
  ldrb w5, [x3, x4]
  cbz w5, .Lroman_gotlen
  add w4, w4, #1
  b .Lroman_slen
.Lroman_gotlen:
  mov x0, #1
  uxtw x2, w4
  mov x16, #4
  svc #0x80
  b .Lroman_loop
.Lroman_next:
  add x20, x20, #8
  b .Lroman_loop
.Lroman_done:
  adrp x1, _nl@PAGE
  add x1, x1, _nl@PAGEOFF
  mov x0, #1
  mov x2, #1
  mov x16, #4
  svc #0x80
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret
RTASM

  emit ""

  # Turing Text Model output
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_read_out_array:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  stp x23, x24, [sp, #-16]!
  mov x19, x0
  mov w20, w1
  mov w21, w2
  adrp x22, _ttm_out_pos@PAGE
  add x22, x22, _ttm_out_pos@PAGEOFF
  ldr w23, [x22]
  mov w24, #0
.Lttm_loop:
  cmp w24, w20
  b.ge .Lttm_done
  cmp w21, #2
  b.eq .Lttm_load16
  ldr w25, [x19, x24, lsl #2]
  b .Lttm_loaded
.Lttm_load16:
  ldrh w25, [x19, x24, lsl #1]
.Lttm_loaded:
  sub w23, w23, w25
  and w23, w23, #0xFF
  mov w0, w23
  rbit w0, w0
  lsr w0, w0, #24
  sub sp, sp, #16
  strb w0, [sp]
  mov x1, sp
  mov x0, #1
  mov x2, #1
  mov x16, #4
  svc #0x80
  add sp, sp, #16
  add w24, w24, #1
  b .Lttm_loop
.Lttm_done:
  str w23, [x22]
  ldp x23, x24, [sp], #16
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret
RTASM

  emit ""

  # Turing Text Model input
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_write_in_array:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  stp x23, x24, [sp, #-16]!
  stp x25, x26, [sp, #-16]!
  mov x19, x0
  mov w20, w1
  mov w21, w2
  adrp x22, _ttm_in_pos@PAGE
  add x22, x22, _ttm_in_pos@PAGEOFF
  ldr w23, [x22]
  mov w24, #0
.Lttm_in_loop:
  cmp w24, w20
  b.ge .Lttm_in_done
  sub sp, sp, #16
  mov x0, #0
  mov x1, sp
  mov x2, #1
  mov x16, #3
  svc #0x80
  cbz x0, .Lttm_in_eof
  ldrb w25, [sp]
  add sp, sp, #16
  rbit w25, w25
  lsr w25, w25, #24
  sub w26, w25, w23
  and w26, w26, #0xFF
  cmp w21, #2
  b.eq .Lttm_in_store16
  str w26, [x19, x24, lsl #2]
  b .Lttm_in_stored
.Lttm_in_store16:
  strh w26, [x19, x24, lsl #1]
.Lttm_in_stored:
  mov w23, w25
  add w24, w24, #1
  b .Lttm_in_loop
.Lttm_in_eof:
  add sp, sp, #16
  b _rt_error_E562
.Lttm_in_done:
  str w23, [x22]
  ldp x25, x26, [sp], #16
  ldp x23, x24, [sp], #16
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret
RTASM

  emit ""

  # Write in scalar (English digit names)
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_write_in_scalar:
  stp x29, x30, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  sub sp, sp, #272
  mov x19, sp
  mov w20, #0
.Lwi_read:
  mov x0, #0
  add x1, x19, w20, uxtw
  mov x2, #1
  mov x16, #3
  svc #0x80
  cbz x0, .Lwi_parse
  ldrb w1, [x19, w20, uxtw]
  cmp w1, #10
  b.eq .Lwi_parse
  add w20, w20, #1
  cmp w20, #255
  b.lt .Lwi_read
.Lwi_parse:
  cbz w20, .Lwi_eof
  strb wzr, [x19, w20, uxtw]
  // Uppercase
  mov w1, #0
.Lwi_upper:
  ldrb w2, [x19, w1, uxtw]
  cbz w2, .Lwi_tokenize
  cmp w2, #97
  b.lt .Lwi_upper_next
  cmp w2, #122
  b.gt .Lwi_upper_next
  sub w2, w2, #32
  strb w2, [x19, w1, uxtw]
.Lwi_upper_next:
  add w1, w1, #1
  b .Lwi_upper
.Lwi_tokenize:
  mov w21, #0     // result
  mov w22, #0     // pos in buffer
.Lwi_tok_loop:
  // Skip spaces
  ldrb w0, [x19, w22, uxtw]
  cbz w0, .Lwi_tok_done
  cmp w0, #32
  b.ne .Lwi_match
  add w22, w22, #1
  b .Lwi_tok_loop
.Lwi_match:
  // Try each digit name
  adrp x10, _digit_names@PAGE
  add x10, x10, _digit_names@PAGEOFF
  adrp x11, _digit_values@PAGE
  add x11, x11, _digit_values@PAGEOFF
  mov w12, #0    // digit name index
  mov w13, #12   // total names
.Lwi_try_name:
  cmp w12, w13
  b.ge .Lwi_bad_token
  // Compare token at x19+w22 with name at x10
  mov w14, #0   // char index in name
  add x15, x19, w22, uxtw
.Lwi_cmp:
  ldrb w16, [x10, w14, uxtw]
  ldrb w17, [x15, w14, uxtw]
  cbz w16, .Lwi_cmp_end   // end of name
  cmp w16, w17
  b.ne .Lwi_next_name
  add w14, w14, #1
  b .Lwi_cmp
.Lwi_cmp_end:
  // Name matched fully. Check token boundary (next char must be space, null, or end)
  ldrb w17, [x15, w14, uxtw]
  cbz w17, .Lwi_matched
  cmp w17, #32
  b.eq .Lwi_matched
  // Not a boundary, try next name
.Lwi_next_name:
  // Advance x10 past current name (find null)
  ldrb w16, [x10]
  add x10, x10, #1
  cbnz w16, .Lwi_next_name
  add w12, w12, #1
  b .Lwi_try_name
.Lwi_matched:
  // result = result * 10 + digit_value
  mov w0, #10
  mul w21, w21, w0
  ldrb w0, [x11, w12, uxtw]
  add w21, w21, w0
  add w22, w22, w14   // advance past matched token
  b .Lwi_tok_loop
.Lwi_tok_done:
  mov w0, w21
  add sp, sp, #272
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  ret
.Lwi_bad_token:
  add sp, sp, #272
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_error_E579
.Lwi_eof:
  add sp, sp, #272
  ldp x21, x22, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x29, x30, [sp], #16
  b _rt_error_E562
RTASM

  emit ""

  # mmap wrapper
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_mmap:
  mov x5, #0
  mov x4, #-1
  mov x3, #0x1002
  mov x2, #3
  mov x1, x0
  mov x0, #0
  mov x16, #197
  svc #0x80
  cmn x0, #1
  b.eq _rt_error_E000
  ret
RTASM

  emit ""

  # Resume helper
  cat <<'RTASM' | while IFS= read -r line; do emit "$line"; done
_rt_resume_1:
  adrp x0, _next_sp@PAGE
  add x0, x0, _next_sp@PAGEOFF
  ldr w1, [x0]
  cbz w1, _rt_error_E632
  sub w1, w1, #1
  str w1, [x0]
  adrp x2, _next_stack@PAGE
  add x2, x2, _next_stack@PAGEOFF
  ldr x3, [x2, x1, lsl #3]
  br x3
RTASM

  emit ""

  # Error handlers
  emit_error_handlers

  # Syslib
  if (( needs_syslib )); then
    emit_native_syslib
  fi
}

emit_error_handlers() {
  local -a codes msgs
  codes=(000 017 123 129 139 200 240 241 275 436 533 562 579 621 632 633)
  msgs=(
    "ICL000I STATEMENT NOT RECOGNIZED DURING EXECUTION"
    "ICL017I EXPRESSION CONTAINS UNRESOLVABLE SYNTAX"
    "ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON"
    "ICL129I NEXT TARGET DOES NOT EXIST"
    "ICL139I ABSTAIN TARGET DOES NOT EXIST"
    "ICL200I VARIABLE REFERENCE NOT RECOGNIZED"
    "ICL240I ARRAY DIMENSION MUST NOT BE ZERO"
    "ICL241I ARRAY SUBSCRIPT OUT OF BOUNDS"
    "ICL275I VALUE EXCEEDS 16 BIT CAPACITY"
    "ICL436I NOTHING TO RETRIEVE FROM STASH"
    "ICL533I RESULT EXCEEDS 32 BIT CAPACITY"
    "ICL562I INPUT DATA EXHAUSTED PREMATURELY"
    "ICL579I INPUT FORMAT NOT RECOGNIZED"
    "ICL621I RESUME WITH VALUE ZERO IS FORBIDDEN"
    "ICL632I PROGRAM ENDED VIA RESUME INSTEAD OF GIVE UP"
    "ICL633I EXECUTION REACHED END WITHOUT GIVE UP"
  )

  local i
  for (( i=1; i<=${#codes[@]}; i++ )); do
    local code="${codes[$i]}"
    local msg="${msgs[$i]}"
    local msglen=${#msg}
    (( msglen++ )) || true  # +1 for newline

    emit "_rt_error_E${code}:"
    emit "  adrp x1, _errmsg_${code}@PAGE"
    emit "  add x1, x1, _errmsg_${code}@PAGEOFF"
    emit "  mov x2, #${msglen}"
    emit "  mov x0, #2"
    emit "  mov x16, #4"
    emit "  svc #0x80"
    emit "  mov x0, #1"
    emit "  mov x16, #1"
    emit "  svc #0x80"
    emit ""
  done
}

emit_native_syslib() {
  emit ""
  emit "// ========== Native Syslib =========="
  emit ""

  # Helper macros via emit
  # 1000: .3 = .1 + .2 (overflow)
  emit "_rt_syslib_1000:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  add w3, w1, w2"
  emit "  mov w4, #65535"
  emit "  cmp w3, w4"
  emit "  b.hi _rt_syslib_1999"
  emit "  adrp x0, _spot_3@PAGE"
  emit "  add x0, x0, _spot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1009: .3 = .1 + .2, .4 = overflow flag
  emit "_rt_syslib_1009:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  add w3, w1, w2"
  emit "  mov w4, #65535"
  emit "  cmp w3, w4"
  emit "  mov w5, #1"
  emit "  mov w6, #2"
  emit "  csel w5, w5, w6, ls"
  emit "  and w3, w3, w4"
  emit "  adrp x0, _spot_3@PAGE"
  emit "  add x0, x0, _spot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  adrp x0, _spot_4@PAGE"
  emit "  add x0, x0, _spot_4@PAGEOFF"
  emit "  str w5, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1010: .3 = .1 - .2 (wraps)
  emit "_rt_syslib_1010:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  sub w3, w1, w2"
  emit "  and w3, w3, #0xFFFF"
  emit "  adrp x0, _spot_3@PAGE"
  emit "  add x0, x0, _spot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1020: .1 = .1 + 1 (wraps)
  emit "_rt_syslib_1020:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  add w1, w1, #1"
  emit "  and w1, w1, #0xFFFF"
  emit "  str w1, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1030: .3 = .1 * .2 (overflow)
  emit "_rt_syslib_1030:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  mul w3, w1, w2"
  emit "  mov w4, #65535"
  emit "  cmp w3, w4"
  emit "  b.hi _rt_syslib_1999"
  emit "  adrp x0, _spot_3@PAGE"
  emit "  add x0, x0, _spot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1039: .3 = .1 * .2, .4 = flag
  emit "_rt_syslib_1039:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  mul w3, w1, w2"
  emit "  mov w4, #65535"
  emit "  cmp w3, w4"
  emit "  mov w5, #1"
  emit "  mov w6, #2"
  emit "  csel w5, w5, w6, ls"
  emit "  and w3, w3, w4"
  emit "  adrp x0, _spot_3@PAGE"
  emit "  add x0, x0, _spot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  adrp x0, _spot_4@PAGE"
  emit "  add x0, x0, _spot_4@PAGEOFF"
  emit "  str w5, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1040: .3 = .1 / .2
  emit "_rt_syslib_1040:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  cbz w2, .Lsys1040_zero"
  emit "  udiv w3, w1, w2"
  emit "  b .Lsys1040_store"
  emit ".Lsys1040_zero:"
  emit "  mov w3, #0"
  emit ".Lsys1040_store:"
  emit "  adrp x0, _spot_3@PAGE"
  emit "  add x0, x0, _spot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1050: .2 = :1 / .1
  emit "_rt_syslib_1050:"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  cbz w2, .Lsys1050_zero"
  emit "  udiv w3, w1, w2"
  emit "  mov w4, #65535"
  emit "  cmp w3, w4"
  emit "  b.hi _rt_syslib_1999"
  emit "  b .Lsys1050_store"
  emit ".Lsys1050_zero:"
  emit "  mov w3, #0"
  emit ".Lsys1050_store:"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1500: :3 = :1 + :2 (overflow)
  emit "_rt_syslib_1500:"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _twospot_2@PAGE"
  emit "  add x0, x0, _twospot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  adds w3, w1, w2"
  emit "  b.cs _rt_syslib_1999"
  emit "  adrp x0, _twospot_3@PAGE"
  emit "  add x0, x0, _twospot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1509: :3 = :1 + :2, :4 = flag
  emit "_rt_syslib_1509:"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _twospot_2@PAGE"
  emit "  add x0, x0, _twospot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  adds w3, w1, w2"
  emit "  mov w5, #1"
  emit "  mov w6, #2"
  emit "  csel w5, w5, w6, cc"
  emit "  adrp x0, _twospot_3@PAGE"
  emit "  add x0, x0, _twospot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  adrp x0, _twospot_4@PAGE"
  emit "  add x0, x0, _twospot_4@PAGEOFF"
  emit "  str w5, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1510: :3 = :1 - :2 (wraps)
  emit "_rt_syslib_1510:"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _twospot_2@PAGE"
  emit "  add x0, x0, _twospot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  sub w3, w1, w2"
  emit "  adrp x0, _twospot_3@PAGE"
  emit "  add x0, x0, _twospot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1520: :1 = .1 $ .2 (mingle)
  emit "_rt_syslib_1520:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w0, [x0]"
  emit "  adrp x1, _spot_2@PAGE"
  emit "  add x1, x1, _spot_2@PAGEOFF"
  emit "  ldr w1, [x1]"
  emit "  bl _rt_mingle"
  emit "  adrp x1, _twospot_1@PAGE"
  emit "  add x1, x1, _twospot_1@PAGEOFF"
  emit "  str w0, [x1]"
  emit "  b _rt_resume_1"
  emit ""

  # 1530: :1 = .1 * .2 (16x16->32)
  emit "_rt_syslib_1530:"
  emit "  adrp x0, _spot_1@PAGE"
  emit "  add x0, x0, _spot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _spot_2@PAGE"
  emit "  add x0, x0, _spot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  mul w3, w1, w2"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1540: :3 = :1 * :2 (overflow)
  emit "_rt_syslib_1540:"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _twospot_2@PAGE"
  emit "  add x0, x0, _twospot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  umull x3, w1, w2"
  emit "  lsr x4, x3, #32"
  emit "  cbnz x4, _rt_syslib_1999"
  emit "  adrp x0, _twospot_3@PAGE"
  emit "  add x0, x0, _twospot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1549: :3 = :1 * :2, :4 = flag
  emit "_rt_syslib_1549:"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _twospot_2@PAGE"
  emit "  add x0, x0, _twospot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  umull x3, w1, w2"
  emit "  lsr x4, x3, #32"
  emit "  mov w5, #1"
  emit "  mov w6, #2"
  emit "  cmp x4, #0"
  emit "  csel w5, w5, w6, eq"
  emit "  adrp x0, _twospot_3@PAGE"
  emit "  add x0, x0, _twospot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  adrp x0, _twospot_4@PAGE"
  emit "  add x0, x0, _twospot_4@PAGEOFF"
  emit "  str w5, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1550: :3 = :1 / :2
  emit "_rt_syslib_1550:"
  emit "  adrp x0, _twospot_1@PAGE"
  emit "  add x0, x0, _twospot_1@PAGEOFF"
  emit "  ldr w1, [x0]"
  emit "  adrp x0, _twospot_2@PAGE"
  emit "  add x0, x0, _twospot_2@PAGEOFF"
  emit "  ldr w2, [x0]"
  emit "  cbz w2, .Lsys1550_zero"
  emit "  udiv w3, w1, w2"
  emit "  b .Lsys1550_store"
  emit ".Lsys1550_zero:"
  emit "  mov w3, #0"
  emit ".Lsys1550_store:"
  emit "  adrp x0, _twospot_3@PAGE"
  emit "  add x0, x0, _twospot_3@PAGEOFF"
  emit "  str w3, [x0]"
  emit "  b _rt_resume_1"
  emit ""

  # 1900: .1 = random 16-bit
  emit "_rt_syslib_1900:"
  emit "  sub sp, sp, #16"
  emit "  mov x0, sp"
  emit "  mov x1, #2"
  emit "  mov x16, #500"
  emit "  svc #0x80"
  emit "  ldrh w0, [sp]"
  emit "  add sp, sp, #16"
  emit "  adrp x1, _spot_1@PAGE"
  emit "  add x1, x1, _spot_1@PAGEOFF"
  emit "  str w0, [x1]"
  emit "  b _rt_resume_1"
  emit ""

  # 1910: .2 = random 0-.1
  emit "_rt_syslib_1910:"
  emit "  sub sp, sp, #16"
  emit "  mov x0, sp"
  emit "  mov x1, #4"
  emit "  mov x16, #500"
  emit "  svc #0x80"
  emit "  ldr w0, [sp]"
  emit "  add sp, sp, #16"
  emit "  adrp x1, _spot_1@PAGE"
  emit "  add x1, x1, _spot_1@PAGEOFF"
  emit "  ldr w1, [x1]"
  emit "  cbz w1, .Lsys1910_zero"
  emit "  add w2, w1, #1"
  emit "  udiv w3, w0, w2"
  emit "  msub w0, w3, w2, w0"
  emit "  b .Lsys1910_store"
  emit ".Lsys1910_zero:"
  emit "  mov w0, #0"
  emit ".Lsys1910_store:"
  emit "  adrp x1, _spot_2@PAGE"
  emit "  add x1, x1, _spot_2@PAGEOFF"
  emit "  str w0, [x1]"
  emit "  b _rt_resume_1"
  emit ""

  # 1999: overflow error
  emit "_rt_syslib_1999:"
  emit "  b _rt_error_E275"
  emit ""
}

# ============================================================
# SECTION 9: Data section
# ============================================================

emit_data() {
  emit ""
  emit "// ========== Data Section =========="
  emit ".section __DATA,__data"
  emit ".align 2"
  emit ""

  # Roman numeral table
  emit "_rtable:"
  emit "  .long 1000, 0"
  emit "  .long 900,  2"
  emit "  .long 500,  5"
  emit "  .long 400,  7"
  emit "  .long 100,  10"
  emit "  .long 90,   12"
  emit "  .long 50,   15"
  emit "  .long 40,   17"
  emit "  .long 10,   20"
  emit "  .long 9,    22"
  emit "  .long 5,    25"
  emit "  .long 4,    27"
  emit "  .long 1,    30"
  emit "  .long 0,    0"
  emit ""
  emit "_rstrings:"
  emit '  .asciz "M"'
  emit '  .asciz "CM"'
  emit '  .asciz "D"'
  emit '  .asciz "CD"'
  emit '  .asciz "C"'
  emit '  .asciz "XC"'
  emit '  .asciz "L"'
  emit '  .asciz "XL"'
  emit '  .asciz "X"'
  emit '  .asciz "IX"'
  emit '  .asciz "V"'
  emit '  .asciz "IV"'
  emit '  .asciz "I"'
  emit ""
  emit "_nl: .byte 10"
  emit ""

  # Error messages
  local -a codes msgs
  codes=(000 017 123 129 139 200 240 241 275 436 533 562 579 621 632 633)
  msgs=(
    "ICL000I STATEMENT NOT RECOGNIZED DURING EXECUTION"
    "ICL017I EXPRESSION CONTAINS UNRESOLVABLE SYNTAX"
    "ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON"
    "ICL129I NEXT TARGET DOES NOT EXIST"
    "ICL139I ABSTAIN TARGET DOES NOT EXIST"
    "ICL200I VARIABLE REFERENCE NOT RECOGNIZED"
    "ICL240I ARRAY DIMENSION MUST NOT BE ZERO"
    "ICL241I ARRAY SUBSCRIPT OUT OF BOUNDS"
    "ICL275I VALUE EXCEEDS 16 BIT CAPACITY"
    "ICL436I NOTHING TO RETRIEVE FROM STASH"
    "ICL533I RESULT EXCEEDS 32 BIT CAPACITY"
    "ICL562I INPUT DATA EXHAUSTED PREMATURELY"
    "ICL579I INPUT FORMAT NOT RECOGNIZED"
    "ICL621I RESUME WITH VALUE ZERO IS FORBIDDEN"
    "ICL632I PROGRAM ENDED VIA RESUME INSTEAD OF GIVE UP"
    "ICL633I EXECUTION REACHED END WITHOUT GIVE UP"
  )

  local i
  for (( i=1; i<=${#codes[@]}; i++ )); do
    emit "_errmsg_${codes[$i]}: .asciz \"${msgs[$i]}\\n\""
  done
  emit ""

  # Digit names for WRITE IN
  emit "_digit_names:"
  emit '  .asciz "ZERO"'
  emit '  .asciz "OH"'
  emit '  .asciz "ONE"'
  emit '  .asciz "TWO"'
  emit '  .asciz "THREE"'
  emit '  .asciz "FOUR"'
  emit '  .asciz "FIVE"'
  emit '  .asciz "SIX"'
  emit '  .asciz "SEVEN"'
  emit '  .asciz "EIGHT"'
  emit '  .asciz "NINE"'
  emit '  .asciz "NINER"'
  emit ""
  emit "_digit_values:"
  emit "  .byte 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9"
  emit ""

  # Statement flags
  emit "_stmt_flags:"
  for (( i=1; i<=stmt_count; i++ )); do
    if (( stmt_negated[$i] )); then
      emit "  .byte 1"
    else
      emit "  .byte 0"
    fi
  done
  emit ""

  # BSS section
  emit ".section __DATA,__bss"
  emit ""

  # Variables
  for var in ${(k)used_spot}; do
    emit ".align 2"
    emit "_spot_${var}: .space 4"
    emit "_spot_${var}_ign: .space 1"
    emit ".align 3"
    emit "_spot_${var}_stash_ptr: .space 8"
    emit "_spot_${var}_stash_sp: .space 4"
  done

  for var in ${(k)used_twospot}; do
    emit ".align 2"
    emit "_twospot_${var}: .space 4"
    emit "_twospot_${var}_ign: .space 1"
    emit ".align 3"
    emit "_twospot_${var}_stash_ptr: .space 8"
    emit "_twospot_${var}_stash_sp: .space 4"
  done

  for var in ${(k)used_tail}; do
    emit ".align 3"
    emit "_tail_${var}_ptr: .space 8"
    emit "_tail_${var}_ndim: .space 4"
    emit "_tail_${var}_dims: .space 32"
    emit "_tail_${var}_ign: .space 1"
    emit ".align 3"
    emit "_tail_${var}_stash_ptr: .space 8"
    emit "_tail_${var}_stash_sp: .space 4"
  done

  for var in ${(k)used_hybrid}; do
    emit ".align 3"
    emit "_hybrid_${var}_ptr: .space 8"
    emit "_hybrid_${var}_ndim: .space 4"
    emit "_hybrid_${var}_dims: .space 32"
    emit "_hybrid_${var}_ign: .space 1"
    emit ".align 3"
    emit "_hybrid_${var}_stash_ptr: .space 8"
    emit "_hybrid_${var}_stash_sp: .space 4"
  done

  # NEXT stack
  emit ".align 3"
  emit "_next_stack: .space 632"
  emit "_next_sp: .space 4"
  emit ""

  # TTM tape positions
  emit "_ttm_out_pos: .space 4"
  emit "_ttm_in_pos: .space 4"
}

# ============================================================
# SECTION 10: Main driver
# ============================================================

main() {
  read_source
  tokenize
  check_politeness
  check_labels
  resolve_come_from
  detect_syslib

  codegen_program

  print -r -- "$asm" | cc -x assembler - -o "$TMPBIN" 2>&2
  local cc_exit=$?
  if [[ $cc_exit -ne 0 ]]; then
    exit 1
  fi
  cat "$TMPBIN"
}

main
