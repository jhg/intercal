#!/bin/zsh
# codegen_x86_64.sh - x86_64 code generation for the INTERCAL bootstrap compiler
# Sourced by intercalc.sh when _INTERCAL_PLATFORM is linux_x86_64
# Generates Intel syntax assembly (matching runtime_linux_x86_64.s)
# Uses System V AMD64 ABI calling convention

# ============================================================
# SECTION 6 override: Expression codegen (x86_64)
# ============================================================

codegen_expr() {
  local id=$1
  local type="${expr_type[$id]}"

  case "$type" in
    CONST)
      local val=${expr_val[$id]}
      emit "  mov eax, ${val}"
      ;;
    VAR_SPOT)
      local num=${expr_val[$id]}
      emit "  lea rcx, [rip + _spot_${num}]"
      emit "  mov eax, [rcx]"
      ;;
    VAR_TWOSPOT)
      local num=${expr_val[$id]}
      emit "  lea rcx, [rip + _twospot_${num}]"
      emit "  mov eax, [rcx]"
      ;;
    ARRAY_TAIL_REF|ARRAY_HYBRID_REF)
      codegen_array_ref $id
      ;;
    ARRAY_TAIL|ARRAY_HYBRID)
      emit "  xor eax, eax"
      ;;
    OP_MINGLE)
      local left=${expr_left[$id]}
      local right=${expr_right[$id]}
      codegen_expr $left
      emit "  push rax"
      codegen_expr $right
      emit "  mov esi, eax"
      emit "  pop rdi"
      emit "  call _rt_mingle"
      ;;
    OP_SELECT)
      local left=${expr_left[$id]}
      local right=${expr_right[$id]}
      codegen_expr $left
      emit "  push rax"
      codegen_expr $right
      emit "  mov esi, eax"
      emit "  pop rdi"
      local w=${expr_width[${expr_left[$id]}]}
      if (( w == 32 )); then
        emit "  mov edx, 32"
      else
        emit "  mov edx, 16"
      fi
      emit "  call _rt_select"
      ;;
    OP_AND|OP_OR|OP_XOR)
      local child=${expr_child[$id]}
      codegen_expr $child
      emit "  mov edi, eax"
      local w=${expr_width[$id]}
      case "$type" in
        OP_AND)
          if (( w == 32 )); then emit "  call _rt_unary_and_32"
          else emit "  call _rt_unary_and_16"; fi ;;
        OP_OR)
          if (( w == 32 )); then emit "  call _rt_unary_or_32"
          else emit "  call _rt_unary_or_16"; fi ;;
        OP_XOR)
          if (( w == 32 )); then emit "  call _rt_unary_xor_32"
          else emit "  call _rt_unary_xor_16"; fi ;;
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
    emit "  dec eax"
    # Bounds check
    emit "  lea rcx, [rip + _${prefix}_${arr_num}_dims]"
    emit "  mov edx, [rcx]"
    emit "  cmp eax, edx"
    emit "  jae _rt_error_E241"
    # Load element
    emit "  lea rcx, [rip + _${prefix}_${arr_num}_ptr]"
    emit "  mov rcx, [rcx]"
    if (( elem_size == 2 )); then
      emit "  movzx eax, word ptr [rcx + rax*2]"
    else
      emit "  mov eax, [rcx + rax*4]"
    fi
  else
    # Multi-dimensional: compute linear index
    local s
    for s in "${sub_ids[@]}"; do
      codegen_expr $s
      emit "  push rax"
    done
    # Now compute linear index: ((s1-1)*d2 + (s2-1))*d3 + ... + (sn-1)
    emit "  xor eax, eax"
    local j
    for (( j=1; j<=nsubs; j++ )); do
      if (( j > 1 )); then
        emit "  lea rcx, [rip + _${prefix}_${arr_num}_dims]"
        emit "  mov edx, [rcx + $(( (j-1) * 4 ))]"
        emit "  imul eax, edx"
      fi
      # Load sub[j] from stack
      local stack_off=$(( (nsubs - j) * 8 ))
      emit "  mov edx, [rsp + ${stack_off}]"
      emit "  dec edx"
      emit "  add eax, edx"
    done
    # Clean stack
    emit "  add rsp, $(( nsubs * 8 ))"
    # Load element
    emit "  lea rcx, [rip + _${prefix}_${arr_num}_ptr]"
    emit "  mov rcx, [rcx]"
    if (( elem_size == 2 )); then
      emit "  movzx eax, word ptr [rcx + rax*2]"
    else
      emit "  mov eax, [rcx + rax*4]"
    fi
  fi
}

# ============================================================
# SECTION 7 override: Statement codegen (x86_64)
# ============================================================

codegen_program() {
  emit ".intel_syntax noprefix"
  emit ".section .text"
  emit ".global main"
  emit ".align 16"
  emit ""
  emit "main:"
  emit "  push rbp"
  emit "  mov rbp, rsp"
  emit "  # Save argc/argv for Label 666"
  emit "  lea rcx, [rip + _rt_argc]"
  emit "  mov [rcx], edi"
  emit "  lea rcx, [rip + _rt_argv]"
  emit "  mov [rcx], rsi"
  emit ""

  local i
  for (( i=1; i<=stmt_count; i++ )); do
    codegen_statement $i
  done

  emit "  jmp _rt_error_E633"
  emit ""

  emit_data
}

codegen_statement() {
  local i=$1
  emit ""
  emit "_stmt_${i}:  # ${stmt_type[$i]}"

  # Abstain check
  local flag_offset=$((i-1))
  emit "  lea rax, [rip + _stmt_flags]"
  emit "  movzx ecx, byte ptr [rax + ${flag_offset}]"
  emit "  test ecx, ecx"
  emit "  jnz _stmt_${i}_end"

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
    UNKNOWN)    emit "  jmp _rt_error_E000" ;;
  esac

  emit "_stmt_${i}_end:"

  # COME FROM redirect
  local lbl="${stmt_label[$i]}"
  if [[ -n "$lbl" ]] && [[ -n "${come_from_target[$lbl]:-}" ]]; then
    local cf_stmt=${come_from_target[$lbl]}
    local cf_offset=$((cf_stmt-1))
    emit "  lea rax, [rip + _stmt_flags]"
    emit "  movzx ecx, byte ptr [rax + ${cf_offset}]"
    emit "  test ecx, ecx"
    emit "  jnz _stmt_${i}_nocf"
    emit "  jmp _stmt_${cf_stmt}"
    emit "_stmt_${i}_nocf:"
  fi
}

codegen_give_up() {
  emit "  xor edi, edi"
  emit "  mov eax, 60"
  emit "  syscall"
}

codegen_probability() {
  local i=$1
  # Use getrandom syscall (318) to get 4 random bytes
  # getrandom(buf, buflen, flags) -> rdi=buf, rsi=buflen, rdx=flags
  emit "  sub rsp, 16"
  emit "  lea rdi, [rsp]"
  emit "  mov esi, 4"
  emit "  xor edx, edx"
  emit "  mov eax, 318"
  emit "  syscall"
  emit "  mov eax, [rsp]"
  emit "  add rsp, 16"
  emit "  xor edx, edx"
  emit "  mov ecx, 100"
  emit "  div ecx"
  emit "  cmp edx, ${stmt_prob[$i]}"
  emit "  jge _stmt_${i}_end"
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
      emit "  lea rax, [rip + _tail_${arr_num}_ptr]"
      emit "  mov rdi, [rax]"
      emit "  lea rax, [rip + _tail_${arr_num}_dims]"
      emit "  mov esi, [rax]"
      emit "  mov edx, 2"
      emit "  call _rt_read_out_array"
      continue
    fi
    if [[ "$item" =~ '^;[0-9]+$' ]]; then
      local arr_num="${item#;}"
      emit "  lea rax, [rip + _hybrid_${arr_num}_ptr]"
      emit "  mov rdi, [rax]"
      emit "  lea rax, [rip + _hybrid_${arr_num}_dims]"
      emit "  mov esi, [rax]"
      emit "  mov edx, 4"
      emit "  call _rt_read_out_array"
      continue
    fi

    # Parse as expression
    parse_text="$item"
    parse_pos=0
    if parse_expr ""; then
      codegen_expr $parse_result
      emit "  mov edi, eax"
      emit "  call _rt_write_roman"
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
      emit "  lea rax, [rip + _tail_${arr_num}_ptr]"
      emit "  mov rdi, [rax]"
      emit "  lea rax, [rip + _tail_${arr_num}_dims]"
      emit "  mov esi, [rax]"
      emit "  mov edx, 2"
      emit "  call _rt_write_in_array"
      continue
    fi
    if [[ "$item" =~ '^;[0-9]+$' ]]; then
      local arr_num="${item#;}"
      emit "  lea rax, [rip + _hybrid_${arr_num}_ptr]"
      emit "  mov rdi, [rax]"
      emit "  lea rax, [rip + _hybrid_${arr_num}_dims]"
      emit "  mov esi, [rax]"
      emit "  mov edx, 4"
      emit "  call _rt_write_in_array"
      continue
    fi

    # Scalar variable
    if [[ "$item" =~ '^\.[0-9]+$' ]]; then
      local vnum="${item#.}"
      emit "  call _rt_write_in_scalar"
      # Check 16-bit overflow
      emit "  cmp eax, 65535"
      emit "  ja _rt_error_E275"
      emit "  lea rcx, [rip + _spot_${vnum}_ign]"
      emit "  movzx edx, byte ptr [rcx]"
      emit "  test edx, edx"
      next_uid; local uid=$REPLY
      emit "  jnz .Lwi_skip_${uid}"
      emit "  lea rcx, [rip + _spot_${vnum}]"
      emit "  mov [rcx], eax"
      emit ".Lwi_skip_${uid}:"
      continue
    fi
    if [[ "$item" =~ '^:[0-9]+$' ]]; then
      local vnum="${item#:}"
      emit "  call _rt_write_in_scalar"
      emit "  lea rcx, [rip + _twospot_${vnum}_ign]"
      emit "  movzx edx, byte ptr [rcx]"
      emit "  test edx, edx"
      next_uid; local uid=$REPLY
      emit "  jnz .Lwi_skip_${uid}"
      emit "  lea rcx, [rip + _twospot_${vnum}]"
      emit "  mov [rcx], eax"
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
    emit "  cmp eax, 65535"
    emit "  ja _rt_error_E275"
    emit "  lea rcx, [rip + _spot_${vnum}_ign]"
    emit "  movzx edx, byte ptr [rcx]"
    emit "  test edx, edx"
    emit "  jnz _stmt_${i}_end"
    emit "  lea rcx, [rip + _spot_${vnum}]"
    emit "  mov [rcx], eax"
  elif [[ "$target" =~ '^:[0-9]+$' ]]; then
    local vnum="${target#:}"
    emit "  lea rcx, [rip + _twospot_${vnum}_ign]"
    emit "  movzx edx, byte ptr [rcx]"
    emit "  test edx, edx"
    emit "  jnz _stmt_${i}_end"
    emit "  lea rcx, [rip + _twospot_${vnum}]"
    emit "  mov [rcx], eax"
  fi
}

codegen_array_elem_assign() {
  local i=$1
  local target="$2"
  local expr_str="$3"

  # Parse target: ,N SUB expr SUB expr ...
  local arr_prefix="${target[1]}"
  local rest="${target[2,-1]}"
  local arr_part="${rest%% SUB*}"
  arr_part="${arr_part%% *}"
  local arr_num="$arr_part"
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
  emit "  push rax"  # save value

  # Parse subscripts
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
    emit "  push rax"
  done

  # Compute linear index for 1D case
  if (( nsubs == 1 )); then
    emit "  pop rax"       # subscript
    emit "  dec eax"       # 0-indexed
    # Bounds check
    emit "  lea rcx, [rip + _${prefix}_${arr_num}_dims]"
    emit "  mov edx, [rcx]"
    emit "  cmp eax, edx"
    emit "  jae _rt_error_E241"
  else
    # Multi-dim: compute linear index
    # Subscripts are on stack in reverse order (last pushed first)
    emit "  xor eax, eax"
    local j
    for (( j=1; j<=nsubs; j++ )); do
      if (( j > 1 )); then
        emit "  lea rcx, [rip + _${prefix}_${arr_num}_dims]"
        emit "  mov edx, [rcx + $(( (j-1) * 4 ))]"
        emit "  imul eax, edx"
      fi
      local stack_off=$(( (nsubs - j) * 8 ))
      emit "  mov edx, [rsp + ${stack_off}]"
      emit "  dec edx"
      emit "  add eax, edx"
    done
    # Clean stack (subscripts)
    emit "  add rsp, $(( nsubs * 8 ))"
  fi

  # Check ignore flag
  emit "  lea rcx, [rip + _${prefix}_${arr_num}_ign]"
  emit "  movzx edx, byte ptr [rcx]"
  emit "  test edx, edx"
  emit "  jnz _stmt_${i}_aeskip"

  # Store element
  emit "  lea rcx, [rip + _${prefix}_${arr_num}_ptr]"
  emit "  mov rcx, [rcx]"
  emit "  pop rdx"  # value
  if (( elem_size == 2 )); then
    emit "  mov [rcx + rax*2], dx"
  else
    emit "  mov [rcx + rax*4], edx"
  fi
  emit "  jmp _stmt_${i}_aedone"
  emit "_stmt_${i}_aeskip:"
  emit "  add rsp, 8"  # discard value
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
  local d
  for d in "${dim_parts[@]}"; do
    d="${d## }"
    d="${d%% }"
    parse_text="$d"
    parse_pos=0
    parse_expr ""
    codegen_expr $parse_result
    emit "  push rax"
  done

  # Store dimensions and compute total size
  emit "  mov r10d, 1"  # total elements
  local j
  for (( j=1; j<=ndims; j++ )); do
    local stack_off=$(( (ndims - j) * 8 ))
    emit "  mov r11d, [rsp + ${stack_off}]"
    # Check dim > 0
    emit "  test r11d, r11d"
    emit "  jz _rt_error_E240"
    # Store dimension
    emit "  lea r12, [rip + _${prefix}_${arr_num}_dims]"
    emit "  mov [r12 + $(( (j-1) * 4 ))], r11d"
    emit "  imul r10d, r11d"
  done
  emit "  add rsp, $(( ndims * 8 ))"

  # Store ndim
  emit "  lea r12, [rip + _${prefix}_${arr_num}_ndim]"
  emit "  mov dword ptr [r12], ${ndims}"

  # Allocate memory: total * elem_size
  if (( elem_size == 2 )); then
    emit "  mov edi, r10d"
    emit "  shl rdi, 1"
  else
    emit "  mov edi, r10d"
    emit "  shl rdi, 2"
  fi
  emit "  call _rt_mmap"

  # Store pointer
  emit "  lea r12, [rip + _${prefix}_${arr_num}_ptr]"
  emit "  mov [r12], rax"
}

codegen_next() {
  local i=$1
  local target_label="${stmt_next_target[$i]}"
  local target_ref="${label_to_stmt[$target_label]:-}"

  if [[ -z "$target_ref" ]]; then
    emit "  jmp _rt_error_E129"
    return
  fi

  # Check NEXT stack depth
  emit "  lea rax, [rip + _next_sp]"
  emit "  mov ecx, [rax]"
  emit "  cmp ecx, 79"
  emit "  jge _rt_error_E123"
  # Push return address
  emit "  lea rdx, [rip + _next_stack]"
  emit "  lea r8, [rip + _stmt_${i}_end]"
  emit "  mov [rdx + rcx*8], r8"
  emit "  inc ecx"
  emit "  mov [rax], ecx"

  if [[ "$target_ref" == "syscall_666" ]]; then
    emit "  jmp _rt_syscall_666"
  elif [[ "$target_ref" == syslib_* ]]; then
    local syslib_num="${target_ref#syslib_}"
    emit "  jmp _rt_syslib_${syslib_num}"
  else
    emit "  jmp _stmt_${target_ref}"
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

  emit "  test eax, eax"
  emit "  jz _rt_error_E621"
  emit "  lea rcx, [rip + _next_sp]"
  emit "  mov edx, [rcx]"
  emit "  sub edx, eax"
  emit "  js _rt_error_E632"
  emit "  mov [rcx], edx"
  emit "  lea r8, [rip + _next_stack]"
  emit "  mov rax, [r8 + rdx*8]"
  emit "  jmp rax"
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

  emit "  lea rcx, [rip + _next_sp]"
  emit "  mov edx, [rcx]"
  emit "  sub edx, eax"
  emit "  jns .Lforget_ok_${i}"
  emit "  xor edx, edx"
  emit ".Lforget_ok_${i}:"
  emit "  mov [rcx], edx"
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
      emit "  jmp _rt_error_E139"
      return
    fi
    local abs_offset=$((target_stmt-1))
    emit "  lea rax, [rip + _stmt_flags]"
    emit "  mov byte ptr [rax + ${abs_offset}], 1"
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
      emit "  jmp _rt_error_E139"
      return
    fi
    local rei_offset=$((target_stmt-1))
    emit "  lea rax, [rip + _stmt_flags]"
    emit "  mov byte ptr [rax + ${rei_offset}], 0"
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

  emit "  lea rax, [rip + _stmt_flags]"

  for g in "${gerunds[@]}"; do
    local types="${gerund_map[$g]:-}"
    [[ -z "$types" ]] && continue
    local j
    for (( j=1; j<=stmt_count; j++ )); do
      for t in ${=types}; do
        if [[ "${stmt_type[$j]}" == "$t" ]]; then
          local ger_offset=$((j-1))
          emit "  mov byte ptr [rax + ${ger_offset}], ${flag_value}"
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
      emit "  lea rax, [rip + _spot_${vnum}_ign]"
      emit "  mov byte ptr [rax], 1"
    elif [[ "$item" =~ '^:[0-9]+$' ]]; then
      local vnum="${item#:}"
      emit "  lea rax, [rip + _twospot_${vnum}_ign]"
      emit "  mov byte ptr [rax], 1"
    elif [[ "$item" =~ '^,[0-9]+$' ]]; then
      local vnum="${item#,}"
      emit "  lea rax, [rip + _tail_${vnum}_ign]"
      emit "  mov byte ptr [rax], 1"
    elif [[ "$item" =~ '^;[0-9]+$' ]]; then
      local vnum="${item#;}"
      emit "  lea rax, [rip + _hybrid_${vnum}_ign]"
      emit "  mov byte ptr [rax], 1"
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
      emit "  lea rax, [rip + _spot_${vnum}_ign]"
      emit "  mov byte ptr [rax], 0"
    elif [[ "$item" =~ '^:[0-9]+$' ]]; then
      local vnum="${item#:}"
      emit "  lea rax, [rip + _twospot_${vnum}_ign]"
      emit "  mov byte ptr [rax], 0"
    elif [[ "$item" =~ '^,[0-9]+$' ]]; then
      local vnum="${item#,}"
      emit "  lea rax, [rip + _tail_${vnum}_ign]"
      emit "  mov byte ptr [rax], 0"
    elif [[ "$item" =~ '^;[0-9]+$' ]]; then
      local vnum="${item#;}"
      emit "  lea rax, [rip + _hybrid_${vnum}_ign]"
      emit "  mov byte ptr [rax], 0"
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

  emit "  lea rax, [rip + _${prefix}_${num}_stash_ptr]"
  emit "  mov rcx, [rax]"
  emit "  test rcx, rcx"
  emit "  jnz .Lstash_ok_${uid}"
  # Allocate stash
  emit "  push rax"
  emit "  mov rdi, 4096"
  emit "  call _rt_mmap"
  emit "  pop rdx"
  emit "  mov [rdx], rax"
  emit "  mov rcx, rax"
  emit ".Lstash_ok_${uid}:"
  # Push value
  emit "  lea rdx, [rip + _${prefix}_${num}_stash_sp]"
  emit "  mov r8d, [rdx]"
  emit "  lea r9, [rip + _${prefix}_${num}]"
  emit "  mov r10d, [r9]"
  emit "  mov [rcx + r8*4], r10d"
  emit "  inc r8d"
  emit "  mov [rdx], r8d"
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

  emit "  lea rdx, [rip + _${prefix}_${num}_stash_sp]"
  emit "  mov r8d, [rdx]"
  emit "  test r8d, r8d"
  emit "  jz _rt_error_E436"
  emit "  dec r8d"
  emit "  mov [rdx], r8d"
  emit "  lea rax, [rip + _${prefix}_${num}_stash_ptr]"
  emit "  mov rcx, [rax]"
  emit "  mov r10d, [rcx + r8*4]"
  emit "  lea r9, [rip + _${prefix}_${num}]"
  emit "  mov [r9], r10d"
}

# ============================================================
# SECTION 8 override: Data section (x86_64)
# ============================================================

emit_data() {
  emit ""
  emit "# ========== Program Data =========="
  # Statement flags (in .data because negated stmts start at 1)
  emit ".section .data"
  emit "_stmt_flags:"
  local i
  for (( i=1; i<=stmt_count; i++ )); do
    if (( stmt_negated[$i] )); then
      emit "  .byte 1"
    else
      emit "  .byte 0"
    fi
  done
  emit ""

  # Program variables BSS
  emit ".section .bss"
  emit ""

  for var in ${(k)used_spot}; do
    emit ".align 4"
    emit "_spot_${var}: .space 4"
    emit "_spot_${var}_ign: .space 1"
    emit ".align 8"
    emit "_spot_${var}_stash_ptr: .space 8"
    emit "_spot_${var}_stash_sp: .space 4"
  done

  for var in ${(k)used_twospot}; do
    emit ".align 4"
    emit "_twospot_${var}: .space 4"
    emit "_twospot_${var}_ign: .space 1"
    emit ".align 8"
    emit "_twospot_${var}_stash_ptr: .space 8"
    emit "_twospot_${var}_stash_sp: .space 4"
  done

  for var in ${(k)used_tail}; do
    emit ".align 8"
    emit "_tail_${var}_ptr: .space 8"
    emit "_tail_${var}_ndim: .space 4"
    emit "_tail_${var}_dims: .space 32"
    emit "_tail_${var}_ign: .space 1"
    emit ".align 8"
    emit "_tail_${var}_stash_ptr: .space 8"
    emit "_tail_${var}_stash_sp: .space 4"
  done

  for var in ${(k)used_hybrid}; do
    emit ".align 8"
    emit "_hybrid_${var}_ptr: .space 8"
    emit "_hybrid_${var}_ndim: .space 4"
    emit "_hybrid_${var}_dims: .space 32"
    emit "_hybrid_${var}_ign: .space 1"
    emit ".align 8"
    emit "_hybrid_${var}_stash_ptr: .space 8"
    emit "_hybrid_${var}_stash_sp: .space 4"
  done
}
