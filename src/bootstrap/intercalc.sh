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
typeset -a stmt_next_target stmt_cf_target stmt_next_from_expr
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

# Compile the pure-INTERCAL syslib (src/syslib/syslib.i) once per
# platform+content-hash and cache the resulting .s under
# ${XDG_CACHE_HOME:-$HOME/.cache}/intercal/. Echoes the cached path
# on stdout so the caller can splice it into the link line.
# Re-uses the cache as long as syslib.i bytes haven't changed.
ensure_syslib_cache() {
  local syslib_src="$ROOT_DIR/src/syslib/syslib.i"
  [[ -f "$syslib_src" ]] || return 1
  local cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/intercal"
  mkdir -p "$cache_root" 2>/dev/null || return 1
  local h=""
  if command -v shasum >/dev/null 2>&1; then
    h=$(shasum -a 256 "$syslib_src" | awk '{print $1}')
  elif command -v sha256sum >/dev/null 2>&1; then
    h=$(sha256sum "$syslib_src" | awk '{print $1}')
  else
    return 1
  fi
  local cache_file="${cache_root}/syslib-${_INTERCAL_PLATFORM}-${h:0:16}.s"
  if [[ ! -f "$cache_file" ]]; then
    # Build cache. Use a fresh shell so our globals don't leak.
    zsh "$SCRIPT_DIR/intercalc.sh" --emit-syslib < "$syslib_src" > "$cache_file" 2>/dev/null \
      || { rm -f "$cache_file"; return 1; }
  fi
  echo "$cache_file"
  return 0
}

# Peephole optimizer: simple line-level redundancy removal on $asm.
# Currently catches: unconditional branch immediately followed by its
# target label (the branch is dead -- fall-through reaches the label
# anyway). Both `b LABEL` (ARM64) and `jmp LABEL` (x86_64) handled.
peephole_optimize() {
  # Note [PeepholeRules]
  #   This pass is the last text-level transformation before assembling.
  #   Rules here must be locally sound (never change observable behaviour
  #   in the surrounding context). Each rule is gated by opt_bisect_check
  #   so --opt-bisect-limit can disable them individually for debugging.
  #   Keep the window small (1-3 lines) so this remains O(n) on the asm.
  local -a lines result
  lines=("${(@f)asm}")
  local n=${#lines[@]}
  result=()
  local i=1
  while (( i <= n )); do
    local cur="${lines[$i]}"
    # Look ahead past blank lines for a matching label.
    local j=$((i+1))
    while (( j <= n )) && [[ -z "${lines[$j]// /}" ]]; do
      (( j++ ))
    done
    local lookahead=""
    (( j <= n )) && lookahead="${lines[$j]}"
    local skip=0

    # Rule R1: branch immediately followed by its target label.
    if [[ "$cur" =~ '^[[:space:]]+b[[:space:]]+(_[a-zA-Z0-9_]+)[[:space:]]*$' ]]; then
      local target="${match[1]}"
      if [[ "$lookahead" == "${target}:"* ]]; then
        opt_bisect_check "peephole_branch_to_next" && skip=1
      fi
    elif [[ "$cur" =~ '^[[:space:]]+jmp[[:space:]]+(_[a-zA-Z0-9_]+)[[:space:]]*$' ]]; then
      local target="${match[1]}"
      if [[ "$lookahead" == "${target}:"* ]]; then
        opt_bisect_check "peephole_jmp_to_next" && skip=1
      fi
    fi

    # Rule R2: identity mov "mov REG, REG" is dead.
    # ARM64: "mov xN, xN" / "mov wN, wN".
    # x86-64: "mov rax, rax" / "mov al, al" etc.
    if (( ! skip )) && [[ "$cur" =~ '^[[:space:]]+mov[[:space:]]+([wxer][a-z0-9]+|al|ax|eax|rax|cx|ecx|rcx|dx|edx|rdx),[[:space:]]*([wxer][a-z0-9]+|al|ax|eax|rax|cx|ecx|rcx|dx|edx|rdx)[[:space:]]*$' ]]; then
      local r1="${match[1]}"
      local r2="${match[2]}"
      if [[ "$r1" == "$r2" ]]; then
        opt_bisect_check "peephole_identity_mov" && skip=1
      fi
    fi

    # Rule R3: collapse runs of blank lines to at most one. Keeps
    # generated asm readable without emitting spurious blanks.
    if (( ! skip )) && [[ -z "${cur// /}" ]] && (( ${#result[@]} > 0 )) && [[ -z "${result[-1]// /}" ]]; then
      opt_bisect_check "peephole_collapse_blanks" && skip=1
    fi

    if (( ! skip )); then
      result+=("$cur")
    fi
    (( i++ ))
  done
  asm=$(printf "%s\n" "${result[@]}")
}

emit_effects() {
  # Note [EffectAnalysis]
  #   Per-statement static analysis of which ICL runtime errors a
  #   statement could raise. Conservative over-approximation: we list
  #   the maximum possible set per statement type. A flow-sensitive
  #   refinement (e.g., proving E275 cannot fire when the RHS is a
  #   small constant) is documented as future work in proposal 20.
  #
  #   Output: per-statement, the set of possible ICL codes.
  local i
  echo "=== Effect / error analysis ==="
  echo "platform:    $_INTERCAL_PLATFORM"
  echo "stmts:       $stmt_count"
  echo
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-?}"
    local body="${stmt_body[$i]:-}"
    local effects=""
    case "$t" in
      ASSIGN)
        effects="E275"
        # Could also be E200 (variable not dimensioned) for arrays;
        # ASSIGN scalars do not trigger that. Include if body looks
        # like array element store.
        if [[ "$body" == *"SUB"* ]]; then
          effects+=" E241 E240"
        fi
        ;;
      ASSIGN_ARRAY)
        effects="E241 E275"
        ;;
      ARRAY_DIM)
        effects="E240"
        ;;
      NEXT)
        effects="E123 E129"
        ;;
      RESUME)
        effects="E621 E632"
        ;;
      FORGET)
        effects="(none)"
        ;;
      ABSTAIN|REINSTATE)
        effects="E139"
        ;;
      COME_FROM)
        effects="E555"
        ;;
      STASH|RETRIEVE)
        if [[ "$t" == "RETRIEVE" ]]; then
          effects="E436"
        else
          effects="(none)"
        fi
        ;;
      IGNORE|REMEMBER)
        effects="(none)"
        ;;
      READ_OUT)
        effects="(none)"
        ;;
      WRITE_IN)
        effects="E562 E579 E533"
        ;;
      GIVE_UP)
        effects="(none)"
        ;;
      *)
        effects="E000 E017"
        ;;
    esac
    printf "  stmt %3d: %-12s -> %s\n" "$i" "$t" "$effects"
  done
}

# Note [RealIR]
#   Three-address IR represented as parallel arrays. The IR is built
#   by build_ir() walking the expression trees of every statement and
#   linearising them into a flat sequence of operations with explicit
#   temporary names (t0, t1, ...). codegen does not yet consume this
#   IR (the tree-walk codegen path remains in place); instead the
#   IR is exposed via --emit-ir-real for inspection, and is the data
#   structure that a future codegen-from-IR rewrite would consume.
#
#   The vocabulary:
#     CONST <dst> <val>           dst = literal
#     LOADV <dst> <varspec>       dst = load(varspec)
#     STORE <varspec> <src>       varspec = src
#     MINGLE <dst> <a> <b>        dst = mingle(a, b)
#     SELECT <dst> <val> <mask>   dst = select(val, mask)
#     UNARY_AND <dst> <src>       dst = unary_and(src)
#     UNARY_OR  <dst> <src>       dst = unary_or(src)
#     UNARY_XOR <dst> <src>       dst = unary_xor(src)
#     STMT      <stmt_idx> <type> separator op marking statement boundary

typeset -a ir_ops
typeset -i _ir_next_temp=0

ir_new_temp() {
  REPLY="t${_ir_next_temp}"
  _ir_next_temp=$((_ir_next_temp + 1))
}

# Walk an expression node (id), append IR ops to ir_ops, return the
# name of the SSA-temp that holds the result in REPLY.
build_ir_expr() {
  local id=$1
  local t="${expr_type[$id]:-?}"
  case "$t" in
    CONST)
      ir_new_temp; local d="$REPLY"
      ir_ops+=("CONST $d ${expr_val[$id]}")
      REPLY="$d"
      ;;
    VAR_SPOT)
      ir_new_temp; local d="$REPLY"
      ir_ops+=("LOADV $d spot_${expr_val[$id]}")
      REPLY="$d"
      ;;
    VAR_TWOSPOT)
      ir_new_temp; local d="$REPLY"
      ir_ops+=("LOADV $d twospot_${expr_val[$id]}")
      REPLY="$d"
      ;;
    OP_AND|OP_OR|OP_XOR)
      build_ir_expr "${expr_child[$id]}"; local s="$REPLY"
      ir_new_temp; local d="$REPLY"
      local op="UNARY_AND"
      [[ "$t" == "OP_OR" ]] && op="UNARY_OR"
      [[ "$t" == "OP_XOR" ]] && op="UNARY_XOR"
      ir_ops+=("$op $d $s")
      REPLY="$d"
      ;;
    OP_MINGLE)
      build_ir_expr "${expr_left[$id]}"; local a="$REPLY"
      build_ir_expr "${expr_right[$id]}"; local b="$REPLY"
      ir_new_temp; local d="$REPLY"
      ir_ops+=("MINGLE $d $a $b")
      REPLY="$d"
      ;;
    OP_SELECT)
      build_ir_expr "${expr_left[$id]}"; local v="$REPLY"
      build_ir_expr "${expr_right[$id]}"; local m="$REPLY"
      ir_new_temp; local d="$REPLY"
      ir_ops+=("SELECT $d $v $m")
      REPLY="$d"
      ;;
    *)
      # Fallback: unknown expression type. Use placeholder.
      ir_new_temp; local d="$REPLY"
      ir_ops+=("OPAQUE $d $t")
      REPLY="$d"
      ;;
  esac
}

build_ir() {
  ir_ops=()
  _ir_next_temp=0
  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-?}"
    ir_ops+=("STMT $i $t")
    if [[ "$t" == "GIVE_UP" ]]; then
      ir_ops+=("GIVE_UP")
      continue
    fi
    if [[ "$t" == "ASSIGN" ]]; then
      local body="${stmt_body[$i]:-}"
      local target="${body%%<-*}"; target="${target## }"; target="${target%% }"
      local rhs="${body#*<-}"; rhs="${rhs## }"; rhs="${rhs%% }"
      # Parse RHS into expression tree (reusing the existing parser).
      parse_text="$rhs"
      parse_pos=0
      parse_expr ""
      local node=$parse_result
      build_ir_expr $node
      local s="$REPLY"
      local vs=""
      if [[ "$target" =~ '^\.([0-9]+)$' ]]; then
        vs="spot_${match[1]}"
      elif [[ "$target" =~ '^:([0-9]+)$' ]]; then
        vs="twospot_${match[1]}"
      fi
      if [[ -n "$vs" ]]; then
        ir_ops+=("STORE $vs $s")
      fi
    fi
  done
}

# Note [LowerIRForStmt]
#   IR-driven codegen for proposal #11. The IR for statement i is the
#   subsequence of ir_ops bracketed by "STMT i ..." and the next
#   "STMT j ..." marker (or end of stream).  We dispatch by op
#   keyword. A statement whose IR is unsupported returns 1 so the
#   caller falls back to legacy tree-walk codegen.
lower_ir_for_stmt() {
  local i=$1
  local op start=-1 end=-1 k
  for (( k=0; k<${#ir_ops[@]}; k++ )); do
    if [[ "${ir_ops[$((k+1))]}" == "STMT $i "* ]]; then
      start=$k
    elif (( start >= 0 )) && [[ "${ir_ops[$((k+1))]}" == "STMT "* ]]; then
      end=$k
      break
    fi
  done
  (( start < 0 )) && return 1
  (( end < 0 )) && end=${#ir_ops[@]}
  local handled=0
  local j=""
  for (( j=start+1; j<end; j++ )); do
    op="${ir_ops[$((j+1))]}"
    case "$op" in
      "GIVE_UP")
        case "$_INTERCAL_PLATFORM" in
          macos_arm64)
            emit "  mov x0, #0"
            emit "  mov x16, #1"
            emit "  svc #0x80"
            ;;
          linux_arm64)
            emit "  mov x0, #0"
            emit "  mov x8, #93"
            emit "  svc #0"
            ;;
          linux_x86_64)
            emit "  mov rdi, 0"
            emit "  mov rax, 60"
            emit "  syscall"
            ;;
        esac
        handled=1
        ;;
      *)
        # Any unsupported op aborts IR-driven lowering for this stmt.
        return 1
        ;;
    esac
  done
  (( handled )) && return 0
  return 1
}

emit_ir_real() {
  build_ir
  echo "=== IR (three-address) ==="
  echo "platform:    $_INTERCAL_PLATFORM"
  echo "ir_ops:      ${#ir_ops[@]}"
  echo
  local op=""
  for op in "${ir_ops[@]}"; do
    echo "  $op"
  done
}

# Note [RegallocForCodegen]
#   Compute a coarse linear-scan allocation per source-language
#   variable (not per SSA name). Result is stored in globals so
#   codegen can consult them when emitting variable touches:
#
#     var_reg[<varspec>]      = "R0".."R3"  if assigned a register
#     var_spilled[<varspec>]  = 1           if spilled to memory
#
#   varspec is "spot_N" or "twospot_N". The data structure is
#   advisory: codegen does not yet alter emitted instructions; it
#   only emits comments under INTERCAL_REGALLOC_HINTS=1, paving the
#   way for actual register-keeping in a future PR.
typeset -A var_reg var_spilled
compute_regalloc_decisions() {
  var_reg=()
  var_spilled=()

  local i
  typeset -A first_def last_use
  for (( i=1; i<=stmt_count; i++ )); do
    local body="${stmt_body[$i]:-}"
    local t="${stmt_type[$i]:-}"
    if [[ "$t" == "ASSIGN" ]]; then
      local target="${body%%<-*}"
      target="${target## }"; target="${target%% }"
      local vk=""
      if [[ "$target" =~ '^\.([0-9]+)$' ]]; then vk="spot_${match[1]}"
      elif [[ "$target" =~ '^:([0-9]+)$' ]]; then vk="twospot_${match[1]}"
      fi
      [[ -n "$vk" ]] && (( ! ${+first_def[$vk]} )) && first_def[$vk]=$i
    fi
    # Track last reference per variable (.N or :N appearing in body).
    local rest="$body"
    while [[ "$rest" =~ '(\.|\:)([0-9]+)' ]]; do
      local mark="${match[1]}" num="${match[2]}"
      local vk=""
      [[ "$mark" == "." ]] && vk="spot_$num"
      [[ "$mark" == ":" ]] && vk="twospot_$num"
      [[ -n "$vk" ]] && last_use[$vk]=$i
      rest="${rest#*${match[1]}${match[2]}}"
    done
  done

  # Sort variables by first_def ascending; assign R0..R3; spill rest.
  local -a vars_sorted
  local vk=""
  for vk in ${(k)first_def}; do
    vars_sorted+=("$vk")
  done
  vars_sorted=(${(o)vars_sorted})

  local R=4
  local -A reg_busy_until
  local v=""
  for v in "${vars_sorted[@]}"; do
    local s=${first_def[$v]}
    local e=${last_use[$v]:-$s}
    local picked=""
    local r=0
    for (( r=0; r<R; r++ )); do
      local until=${reg_busy_until[$r]:-0}
      if (( until < s )); then
        picked=$r
        break
      fi
    done
    if [[ -n "$picked" ]]; then
      reg_busy_until[$picked]=$e
      var_reg[$v]="R${picked}"
    else
      var_spilled[$v]=1
    fi
  done
}

emit_regalloc() {
  # Note [LinearScanDemo]
  #   Poletto-Sarkar linear-scan over SSA-versioned variables. We
  #   compute live intervals as: definition statement (start) and
  #   the last statement that mentions the SSA name (end).
  #
  #   For our demo: each SSA value is named "spot_N.V" or "twospot_N.V"
  #   following --emit-ssa. Last-use is approximated as the last
  #   statement i where the variable .N appears in the body.
  #
  #   R = 4 virtual registers. Spill heuristic: when R intervals are
  #   active and a new one starts, spill the active interval with the
  #   farthest endpoint (per the paper); if the new interval outlives
  #   every active one, spill the new interval itself.
  #
  #   This is a teaching dump. Codegen does not consume the output.
  local i
  echo "=== Liveness + linear-scan ==="
  echo "platform:    $_INTERCAL_PLATFORM"
  echo "stmts:       $stmt_count"
  echo "registers:   R0 R1 R2 R3 (4 virtual)"
  echo

  # Pass 1: collect SSA-versioned defs and their statement indices.
  # Reuse the SSA logic from emit_ssa: each ASSIGN to .N or :N is a
  # fresh def. RETRIEVE bumps version too.
  local -A var_version
  local -a def_name def_start
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-}"
    local body="${stmt_body[$i]:-}"
    case "$t" in
      ASSIGN)
        local target="${body%%<-*}"
        target="${target## }"; target="${target%% }"
        local vk=""
        if [[ "$target" =~ '^\.([0-9]+)$' ]]; then
          vk="spot_${match[1]}"
        elif [[ "$target" =~ '^:([0-9]+)$' ]]; then
          vk="twospot_${match[1]}"
        fi
        [[ -z "$vk" ]] && continue
        local cur="${var_version[$vk]:-0}"
        cur=$((cur + 1))
        var_version[$vk]=$cur
        def_name+=("${vk}.${cur}")
        def_start+=($i)
        ;;
      RETRIEVE)
        local vlist="${body#RETRIEVE }"
        for tok in ${=vlist}; do
          tok="${tok## }"; tok="${tok%% }"
          [[ -z "$tok" ]] && continue
          local vk=""
          if [[ "$tok" =~ '^\.([0-9]+)$' ]]; then
            vk="spot_${match[1]}"
          elif [[ "$tok" =~ '^:([0-9]+)$' ]]; then
            vk="twospot_${match[1]}"
          fi
          [[ -z "$vk" ]] && continue
          local cur="${var_version[$vk]:-0}"
          cur=$((cur + 1))
          var_version[$vk]=$cur
          def_name+=("${vk}.${cur}")
          def_start+=($i)
        done
        ;;
    esac
  done

  # Pass 2: compute end statement (last use) per def. Approximate by
  # walking forward and recording the highest stmt index that
  # mentions the source-language variable name (.N or :N).
  local n_defs=${#def_name[@]}
  local -a def_end
  local d=""
  for (( d=1; d<=n_defs; d++ )); do
    local name="${def_name[$d]}"
    local vkey="${name%.*}"
    local pretty=""
    if [[ "$vkey" == spot_* ]]; then
      pretty=".${vkey#spot_}"
    elif [[ "$vkey" == twospot_* ]]; then
      pretty=":${vkey#twospot_}"
    fi
    local start=${def_start[$d]}
    local end=$start
    # Walk forward; stop at next definition of same vkey.
    local j=""
    for (( j=start+1; j<=stmt_count; j++ )); do
      local b="${stmt_body[$j]:-}"
      # Stop if a later def of the same variable replaces this one.
      if (( d < n_defs )) && [[ "${def_name[$((d+1))]:-}" == "${vkey}."* ]]; then
        if (( ${def_start[$((d+1))]:-stmt_count+1} == j )); then
          break
        fi
      fi
      if [[ "$b" == *"$pretty"* ]]; then
        end=$j
      fi
    done
    def_end+=($end)
  done

  echo "live intervals:"
  for (( d=1; d<=n_defs; d++ )); do
    printf "  %s: [%d, %d]\n" "${def_name[$d]}" "${def_start[$d]}" "${def_end[$d]}"
  done
  echo

  # Pass 3: linear scan. Sort intervals by start (already by
  # construction); R=4. Active set: indices of intervals currently
  # using a register, sorted by end-point.
  local R=4
  local -a active   # indices into def_name (1-based)
  local -A reg_of   # def-index -> register slot 0..R-1
  local -A free_regs
  local k=""
  for (( k=0; k<R; k++ )); do
    free_regs[$k]=1
  done
  local -A spilled

  expire_old() {
    local current_start=$1
    local -a survivors
    for idx in "${active[@]}"; do
      local e=${def_end[$idx]}
      if (( e >= current_start )); then
        survivors+=("$idx")
      else
        # Free this interval's register
        local r=${reg_of[$idx]}
        free_regs[$r]=1
      fi
    done
    active=("${survivors[@]}")
  }

  pick_free_reg() {
    local k=""
    for (( k=0; k<R; k++ )); do
      if (( ${+free_regs[$k]} )) && (( free_regs[$k] )); then
        REPLY=$k
        return 0
      fi
    done
    return 1
  }

  spill_at() {
    # Spill the active interval with the farthest endpoint.
    local farthest_idx="" farthest_end=-1
    for idx in "${active[@]}"; do
      local e=${def_end[$idx]}
      if (( e > farthest_end )); then
        farthest_end=$e
        farthest_idx=$idx
      fi
    done
    REPLY=$farthest_idx
  }

  echo "linear-scan trace:"
  for (( d=1; d<=n_defs; d++ )); do
    local s=${def_start[$d]}
    expire_old $s
    if (( ${#active[@]} == R )); then
      spill_at
      local victim=$REPLY
      if (( ${def_end[$victim]} > def_end[$d] )); then
        # Spill victim, give its register to d.
        local r=${reg_of[$victim]}
        unset "reg_of[$victim]"
        spilled[$victim]=1
        reg_of[$d]=$r
        # Replace victim in active with d (re-sort by end ascending).
        local -a new_active
        for idx in "${active[@]}"; do
          [[ "$idx" == "$victim" ]] && continue
          new_active+=("$idx")
        done
        new_active+=($d)
        active=("${new_active[@]}")
        printf "  %s: spill %s -> R%d (taken from %s)\n" \
          "${def_name[$d]}" "${def_name[$victim]}" "$r" "${def_name[$victim]}"
      else
        # Spill d itself.
        spilled[$d]=1
        printf "  %s: spill (lives longer than every active)\n" "${def_name[$d]}"
      fi
    else
      pick_free_reg
      local r=$REPLY
      free_regs[$r]=0
      reg_of[$d]=$r
      active+=($d)
      printf "  %s: assign R%d\n" "${def_name[$d]}" "$r"
    fi
  done

  echo
  echo "active set after scan: ${#active[@]} intervals"
  echo "spilled: ${(@k)spilled}"
}

emit_sccp() {
  # Note [SCCPAnalysis]
  #   Wegman-Zadeck Sparse Conditional Constant Propagation, applied
  #   at the per-variable-version granularity established by --emit-ssa.
  #   Three-element lattice per SSA value: TOP < CONST(c) < BOTTOM.
  #
  #   Simplification for our scope: we model only ASSIGN of either a
  #   constant (#N) or a previously-seen variable (.M). All other
  #   expression forms (mingle, select, syslib results) are BOTTOM.
  #   This is a teaching dump, not a real codegen-feeding analysis.
  #
  #   Output: per-version lattice value. Syslib calls and WRITE IN
  #   reads are BOTTOM (runtime-dependent).
  local i
  echo "=== SCCP results ==="
  echo "platform:    $_INTERCAL_PLATFORM"

  # Per-variable current value (concrete int or BOTTOM/TOP marker).
  # We track only spot_N and twospot_N here.
  local -A var_lattice
  local -A var_version
  # Sequence of (version, lattice-string) for output preservation.
  local -a output_lines

  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-}"
    local body="${stmt_body[$i]:-}"
    case "$t" in
      ASSIGN)
        local lhs="${body%%<-*}"; lhs="${lhs## }"; lhs="${lhs%% }"
        local rhs="${body#*<-}"; rhs="${rhs## }"; rhs="${rhs%% }"
        local lkey=""
        if [[ "$lhs" =~ '^\.([0-9]+)$' ]]; then
          lkey="spot_${match[1]}"
        elif [[ "$lhs" =~ '^:([0-9]+)$' ]]; then
          lkey="twospot_${match[1]}"
        fi
        [[ -z "$lkey" ]] && continue
        local cur="${var_version[$lkey]:-0}"
        cur=$((cur + 1))
        var_version[$lkey]=$cur
        # Determine RHS lattice value.
        local rhs_lattice=""
        # Strip outer apostrophes/quotes in case of grouping.
        local r="${rhs//\'/}"
        r="${r//\"/}"
        r="${r## }"
        r="${r%% }"
        if [[ "$r" =~ '^#([0-9]+)$' ]]; then
          rhs_lattice="CONST(${match[1]})"
        elif [[ "$r" =~ '^\.([0-9]+)$' ]]; then
          local rkey="spot_${match[1]}"
          if [[ -n "${var_lattice[$rkey]:-}" ]]; then
            rhs_lattice="${var_lattice[$rkey]}"
          else
            rhs_lattice="TOP"
          fi
        elif [[ "$r" =~ '^:([0-9]+)$' ]]; then
          local rkey="twospot_${match[1]}"
          if [[ -n "${var_lattice[$rkey]:-}" ]]; then
            rhs_lattice="${var_lattice[$rkey]}"
          else
            rhs_lattice="TOP"
          fi
        else
          rhs_lattice="BOTTOM"
        fi
        var_lattice[$lkey]=$rhs_lattice
        output_lines+=("${lkey}.${cur} = ${rhs_lattice}")
        ;;
      WRITE_IN)
        # Each variable read is a fresh BOTTOM def.
        local items="${body#WRITE IN }"
        items="${items## }"
        for tok in ${=items}; do
          tok="${tok## }"; tok="${tok%% }"
          [[ -z "$tok" ]] && continue
          local vk=""
          if [[ "$tok" =~ '^\.([0-9]+)$' ]]; then
            vk="spot_${match[1]}"
          elif [[ "$tok" =~ '^:([0-9]+)$' ]]; then
            vk="twospot_${match[1]}"
          fi
          [[ -z "$vk" ]] && continue
          local cur="${var_version[$vk]:-0}"
          cur=$((cur + 1))
          var_version[$vk]=$cur
          var_lattice[$vk]="BOTTOM"
          output_lines+=("${vk}.${cur} = BOTTOM")
        done
        ;;
    esac
  done

  echo "ssa values:  ${#output_lines[@]}"
  echo
  for l in "${output_lines[@]}"; do
    echo "  $l"
  done
}

# Note [WegmanZadeckSCCP]
#   Full Wegman-Zadeck SCCP applied to a simplified INTERCAL model.
#   Per the 1991 paper:
#     - Three-element lattice TOP < CONST(c) < BOTTOM.
#     - A CFG worklist of (pred, succ) edges plus an SSA worklist of
#       (def_stmt) entries. Edges are not visited until they are
#       proven executable; defs are not re-evaluated until an edge
#       into them is found executable.
#     - A monotone meet at every statement with multiple incoming
#       executable edges. INTERCAL has only one such confluence: the
#       statement after a COME FROM target.
#
#   Simplifications kept from the existing emit_sccp:
#     - Variable lattice tracked at the *source-language* level
#       (.N or :N), not per SSA name. The output reports the final
#       lattice value at each statement boundary.
#     - RHS evaluation handles only literal-and-copy chains; any
#       computed expression yields BOTTOM.
#
#   This is still a teaching dump but with proper executable-edge
#   gating and worklist semantics.
emit_sccp_wz() {
  echo "=== Wegman-Zadeck SCCP ==="
  echo "platform:    $_INTERCAL_PLATFORM"
  echo "stmts:       $stmt_count"

  # outgoing_<i>_<vk> = "TOP" | "CONST(N)" | "BOTTOM"
  typeset -A outgoing
  # exec_into[i] = 1 if any incoming edge has been proven executable.
  typeset -A exec_into
  exec_into[1]=1

  # Predecessors. For most i, pred is i-1. For the statement after a
  # labelled stmt that has an incoming COME FROM, the predecessor set
  # is { i-1, come_from_source }. We model a NEXT or NEXT_FROM target
  # as also having edge from the NEXT site.
  typeset -A preds
  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    local plist=""
    if (( i > 1 )); then plist="$((i-1))"; fi
    # NEXT and NEXT_FROM targets receive an edge from the source.
    if [[ -n "${stmt_label[$i]:-}" ]]; then
      local lbl="${stmt_label[$i]}"
      local s=""
      for (( s=1; s<=stmt_count; s++ )); do
        local st="${stmt_type[$s]:-}"
        if [[ "$st" == "NEXT" || "$st" == "NEXT_FROM" ]] \
           && [[ "${stmt_next_target[$s]:-}" == "$lbl" ]]; then
          plist+=" $s"
        fi
      done
    fi
    preds[$i]="$plist"
  done

  # Meet of two lattice values; result placed in REPLY.
  meet_lattice() {
    local a=$1 b=$2
    if [[ "$a" == "TOP" ]]; then REPLY="$b"; return; fi
    if [[ "$b" == "TOP" ]]; then REPLY="$a"; return; fi
    if [[ "$a" == "BOTTOM" || "$b" == "BOTTOM" ]]; then REPLY="BOTTOM"; return; fi
    if [[ "$a" == "$b" ]]; then REPLY="$a"; return; fi
    REPLY="BOTTOM"
  }

  # Process statement i: compute outgoing from the meet of its
  # executable preds' outgoing values, then evaluate RHS for ASSIGN.
  # Return non-zero in $? if outgoing changed.
  process_stmt() {
    local i=$1
    typeset -A incoming
    local p_str="${preds[$i]:-}"
    local p=""
    for p in ${=p_str}; do
      [[ -z "$p" ]] && continue
      (( ${exec_into[$p]:-0} )) || continue
      # Merge p's outgoing into incoming via meet.
      local k=""
      for k in ${(k)outgoing}; do
        if [[ "$k" == "${p}_"* ]]; then
          local vk="${k#${p}_}"
          local v="${outgoing[$k]}"
          local prev="${incoming[$vk]:-TOP}"
          meet_lattice "$prev" "$v"
          incoming[$vk]="$REPLY"
        fi
      done
    done

    local body="${stmt_body[$i]:-}"
    local t="${stmt_type[$i]:-}"
    if [[ "$t" == "ASSIGN" ]]; then
      local lhs="${body%%<-*}"; lhs="${lhs## }"; lhs="${lhs%% }"
      local rhs="${body#*<-}"; rhs="${rhs## }"; rhs="${rhs%% }"
      local lkey=""
      if [[ "$lhs" =~ '^\.([0-9]+)$' ]]; then lkey="spot_${match[1]}"
      elif [[ "$lhs" =~ '^:([0-9]+)$' ]]; then lkey="twospot_${match[1]}"
      fi
      if [[ -n "$lkey" ]]; then
        local r="${rhs//\'/}"; r="${r//\"/}"; r="${r## }"; r="${r%% }"
        local lat="BOTTOM"
        if [[ "$r" =~ '^#([0-9]+)$' ]]; then
          lat="CONST(${match[1]})"
        elif [[ "$r" =~ '^\.([0-9]+)$' ]]; then
          lat="${incoming[spot_${match[1]}]:-TOP}"
        elif [[ "$r" =~ '^:([0-9]+)$' ]]; then
          lat="${incoming[twospot_${match[1]}]:-TOP}"
        fi
        incoming[$lkey]="$lat"
      fi
    fi

    # Compare with previous outgoing[i_*]; record changes.
    local changed=0
    local k=""
    for k in ${(k)incoming}; do
      local oldv="${outgoing[${i}_${k}]:-UNSET}"
      local newv="${incoming[$k]}"
      if [[ "$oldv" != "$newv" ]]; then
        outgoing[${i}_${k}]="$newv"
        changed=1
      fi
    done
    return $((1 - changed))
  }

  # CFG worklist of statement indices.
  typeset -a worklist
  worklist=(1)

  while (( ${#worklist[@]} > 0 )); do
    local cur="${worklist[1]}"
    worklist=("${worklist[@]:1}")
    if process_stmt "$cur"; then
      # Outgoing changed: enqueue successors and mark them executable.
      local succ=0
      for succ in $((cur+1)); do
        (( succ > stmt_count )) && continue
        exec_into[$succ]=1
        worklist+=("$succ")
      done
      # NEXT/NEXT_FROM/COME FROM successors.
      local t="${stmt_type[$cur]:-}"
      if [[ "$t" == "NEXT" || "$t" == "NEXT_FROM" ]]; then
        local lbl="${stmt_next_target[$cur]:-}"
        local i2=""
        for (( i2=1; i2<=stmt_count; i2++ )); do
          if [[ "${stmt_label[$i2]:-}" == "$lbl" ]]; then
            exec_into[$i2]=1
            worklist+=("$i2")
            break
          fi
        done
      fi
    fi
  done

  # Output: per-statement final lattice for tracked variables.
  echo "executable statements: ${#exec_into[@]}"
  echo
  echo "lattice at each statement boundary:"
  for (( i=1; i<=stmt_count; i++ )); do
    local printed=0
    local k=""
    for k in ${(ko)outgoing}; do
      if [[ "$k" == "${i}_"* ]]; then
        local vk="${k#${i}_}"
        printf "  stmt %2d: %-12s = %s\n" "$i" "$vk" "${outgoing[$k]}"
        printed=1
      fi
    done
    (( ! printed )) && (( ${exec_into[$i]:-0} )) \
      && printf "  stmt %2d: (no tracked vars)\n" "$i"
  done
}

emit_ssa() {
  # Note [SSAAnalysis]
  #   Analysis-only SSA construction following Braun et al. (2013):
  #   readVariable / writeVariable / sealBlock / addPhiOperands /
  #   tryRemoveTrivialPhi. Block-parameter form (Cranelift-style)
  #   rather than phi nodes. Codegen is unchanged; this is read-only.
  #
  #   Variable namespace: spot_N (16-bit), twospot_N (32-bit),
  #   tail_N (16-bit array), hybrid_N (32-bit array). Each definition
  #   gets a version number; uses are not explicitly named here (the
  #   dump shows the def-version per assignment for didactic clarity).
  #
  #   Limitations: arrays are treated as a single SSA value per name
  #   (we do not track per-element versions); STASH/RETRIEVE are
  #   modelled as full re-definitions. A real codegen-feeding SSA
  #   would need finer-grained models.
  local i
  echo "=== SSA form ==="
  echo "platform:    $_INTERCAL_PLATFORM"
  echo "stmts:       $stmt_count"

  # Pass 1: identify basic-block leaders (same as emit_cfg).
  local -A is_leader
  is_leader[1]=1
  for (( i=1; i<=stmt_count; i++ )); do
    [[ -n "${stmt_label[$i]:-}" ]] && is_leader[$i]=1
    case "${stmt_type[$i]:-}" in
      NEXT|NEXT_FROM|RESUME|GIVE_UP)
        (( i+1 <= stmt_count )) && is_leader[$((i+1))]=1
        ;;
    esac
    local lbl="${stmt_label[$i]:-}"
    if [[ -n "$lbl" ]] && [[ -n "${come_from_target[$lbl]:-}" ]]; then
      (( i+1 <= stmt_count )) && is_leader[$((i+1))]=1
      is_leader[${come_from_target[$lbl]}]=1
    fi
  done

  # Per-variable version counter.
  local -A var_version
  # Per-statement assigned-var record (var-name -> ssa version).
  local -A stmt_def_var stmt_def_ver

  # Pass 2: walk statements, assign SSA versions to variable defs.
  # We extract the LHS variable from ASSIGN/STORE/DIM/ARRAY_DIM bodies.
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-}"
    local body="${stmt_body[$i]:-}"
    case "$t" in
      ASSIGN)
        local target="${body%%<-*}"
        target="${target## }"
        target="${target%% }"
        local vkey=""
        if [[ "$target" =~ '^\.([0-9]+)$' ]]; then
          vkey="spot_${match[1]}"
        elif [[ "$target" =~ '^:([0-9]+)$' ]]; then
          vkey="twospot_${match[1]}"
        fi
        if [[ -n "$vkey" ]]; then
          local cur="${var_version[$vkey]:-0}"
          cur=$((cur + 1))
          var_version[$vkey]=$cur
          stmt_def_var[$i]=$vkey
          stmt_def_ver[$i]=$cur
        fi
        ;;
      ARRAY_DIM)
        # The body shape "DIM ,N" or "DIM ;N" is parsed by codegen;
        # we do not extract the array name here for SSA dump (single-
        # version model for arrays).
        ;;
      RETRIEVE)
        # RETRIEVE pops a stashed copy; treat as a fresh def of every
        # named variable. The body is the var-list.
        local vlist="${body#RETRIEVE }"
        for tok in ${=vlist}; do
          tok="${tok## }"
          tok="${tok%% }"
          [[ -z "$tok" ]] && continue
          local vkey=""
          if [[ "$tok" =~ '^\.([0-9]+)$' ]]; then
            vkey="spot_${match[1]}"
          elif [[ "$tok" =~ '^:([0-9]+)$' ]]; then
            vkey="twospot_${match[1]}"
          fi
          if [[ -n "$vkey" ]]; then
            local cur="${var_version[$vkey]:-0}"
            cur=$((cur + 1))
            var_version[$vkey]=$cur
          fi
        done
        ;;
    esac
  done

  # Build block boundaries and assign block ids.
  local -A stmt_block
  local blk=-1
  for (( i=1; i<=stmt_count; i++ )); do
    if (( ${is_leader[$i]:-0} )); then
      blk=$((blk + 1))
    fi
    stmt_block[$i]=$blk
  done
  local total_blocks=$((blk + 1))
  local total_versions=0
  local k=""
  for k in "${(@v)var_version}"; do
    total_versions=$((total_versions + k))
  done

  echo "blocks:      $total_blocks"
  echo "ssa values:  $total_versions"
  echo

  # Pass 3: emit per-block listing with SSA names for assignments.
  local -a blk_starts blk_ends
  blk_starts[1]=1
  blk=0
  for (( i=2; i<=stmt_count; i++ )); do
    if (( ${is_leader[$i]:-0} )); then
      blk_ends[$((blk + 1))]=$((i - 1))
      blk=$((blk + 1))
      blk_starts[$((blk + 1))]=$i
    fi
  done
  blk_ends[$((blk + 1))]=$stmt_count

  local b=""
  for (( b=1; b<=total_blocks; b++ )); do
    local s=${blk_starts[$b]}
    local e=${blk_ends[$b]}
    local first_label="${stmt_label[$s]:-}"
    local hdr="block B$((b - 1)):"
    [[ -n "$first_label" ]] && hdr+="  [label ${first_label}]"
    echo "$hdr"
    for (( i=s; i<=e; i++ )); do
      local t="${stmt_type[$i]:-?}"
      if [[ -n "${stmt_def_var[$i]:-}" ]]; then
        local vk="${stmt_def_var[$i]}"
        local vv="${stmt_def_ver[$i]}"
        printf "  stmt %3d: %s.%d = %s\n" "$i" "$vk" "$vv" "$t"
      else
        printf "  stmt %3d: %s\n" "$i" "$t"
      fi
    done
    echo
  done
}

emit_ir_full() {
  # Note [IRFullDump]
  #   This is the inspection-only landing of proposal 9 (Three-address
  #   IR feeding codegen). It combines what --emit-cfg and --emit-3addr
  #   show into one report: each basic block is enumerated, then the
  #   ops within it are listed in three-address form, then outgoing
  #   edges. Codegen still walks the parse tree directly; this dump
  #   lives parallel to it. The follow-up work is to make codegen
  #   consume the same model. See improvement-proposals.md prop 9.
  local i
  echo "=== Three-address IR + CFG ==="
  echo "platform:  $_INTERCAL_PLATFORM"
  echo "stmts:     $stmt_count"
  echo "ops:       $stmt_count (one IR op per source statement at this layer)"
  echo

  # Reuse leader-detection from emit_cfg.
  local -A is_leader
  is_leader[1]=1
  for (( i=1; i<=stmt_count; i++ )); do
    [[ -n "${stmt_label[$i]:-}" ]] && is_leader[$i]=1
    case "${stmt_type[$i]:-}" in
      NEXT|NEXT_FROM|RESUME|GIVE_UP)
        (( i+1 <= stmt_count )) && is_leader[$((i+1))]=1
        ;;
    esac
    local lbl="${stmt_label[$i]:-}"
    if [[ -n "$lbl" ]] && [[ -n "${come_from_target[$lbl]:-}" ]]; then
      (( i+1 <= stmt_count )) && is_leader[$((i+1))]=1
      is_leader[${come_from_target[$lbl]}]=1
    fi
  done

  # Walk blocks; for each, emit the 3addr-style listing.
  local blk_id=-1
  local in_block=0
  for (( i=1; i<=stmt_count; i++ )); do
    if (( ${is_leader[$i]:-0} )); then
      (( in_block )) && echo
      blk_id=$((blk_id + 1))
      local first_label="${stmt_label[$i]:-}"
      local hdr="block B${blk_id}:"
      [[ -n "$first_label" ]] && hdr+=" [label ${first_label}]"
      echo "$hdr"
      in_block=1
    fi
    local t="${stmt_type[$i]:-?}"
    local body="${stmt_body[$i]:-}"
    local lbl="${stmt_label[$i]:-}"
    local prefix="${i}:"
    [[ -n "$lbl" ]] && prefix+="(${lbl})"
    (( stmt_polite[$i] )) && prefix+=" PLEASE"
    (( stmt_negated[$i] )) && prefix+=" NOT"
    case "$t" in
      ASSIGN)        echo "  ${prefix} ASSIGN  ${body}" ;;
      ASSIGN_ARRAY)  echo "  ${prefix} STORE   ${body}" ;;
      ARRAY_DIM)     echo "  ${prefix} DIM     ${body}" ;;
      NEXT)          echo "  ${prefix} NEXT    -> label ${stmt_next_target[$i]:-?}" ;;
      RESUME)        echo "  ${prefix} RESUME  ${body}" ;;
      FORGET)        echo "  ${prefix} FORGET  ${body}" ;;
      ABSTAIN|REINSTATE) echo "  ${prefix} ${t}  ${body}" ;;
      COME_FROM)     echo "  ${prefix} COME_FROM <- label ${stmt_cf_target[$i]:-?}" ;;
      IGNORE|REMEMBER|STASH|RETRIEVE) echo "  ${prefix} ${t}  ${body}" ;;
      READ_OUT|WRITE_IN) echo "  ${prefix} ${t} ${body}" ;;
      GIVE_UP)       echo "  ${prefix} GIVE_UP" ;;
      *)             echo "  ${prefix} ${t}  ${body}" ;;
    esac
  done
  echo
}

emit_tokens() {
  # Inspection-only: print a token-level statement table, the layer
  # below --emit-3addr and --emit-cfg. Useful for confirming that the
  # lexer is classifying each statement correctly before any later
  # analysis runs.
  local i
  echo "=== Token table ==="
  echo "platform:  $_INTERCAL_PLATFORM"
  echo "stmts:     $stmt_count"
  echo
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-?}"
    local lbl="${stmt_label[$i]:-}"
    local body="${stmt_body[$i]:-}"
    local mods=""
    (( stmt_polite[$i] )) && mods+=" PLEASE"
    (( stmt_negated[$i] )) && mods+=" NOT"
    [[ -n "$lbl" ]] && mods+=" (label ${lbl})"
    # Truncate body for readability
    local body_short="${body:0:60}"
    [[ ${#body} -gt 60 ]] && body_short+="..."
    printf "  stmt %3d:%-12s %-12s %s\n" "$i" "$mods" "$t" "$body_short"
  done
}

emit_cfg() {
  # Inspection-only: print a control-flow graph view of the parsed
  # program. The shape is the same one LLVM, GCC, rustc, Go and the
  # rest use as their first-class IR; this dump is read-only and does
  # not feed into codegen, which still emits per-statement templates.
  local i

  # Pass 1: identify basic-block leaders.
  local -A is_leader
  is_leader[1]=1
  for (( i=1; i<=stmt_count; i++ )); do
    [[ -n "${stmt_label[$i]:-}" ]] && is_leader[$i]=1
    case "${stmt_type[$i]:-}" in
      NEXT|NEXT_FROM|RESUME|GIVE_UP)
        (( i+1 <= stmt_count )) && is_leader[$((i+1))]=1
        ;;
    esac
    # Statement at a label that has a COME FROM ends a block.
    local lbl="${stmt_label[$i]:-}"
    if [[ -n "$lbl" ]] && [[ -n "${come_from_target[$lbl]:-}" ]]; then
      (( i+1 <= stmt_count )) && is_leader[$((i+1))]=1
      is_leader[${come_from_target[$lbl]}]=1
    fi
  done

  # Pass 2: assign block id to each leader.
  local -A stmt_block
  local blk=-1
  for (( i=1; i<=stmt_count; i++ )); do
    if (( ${is_leader[$i]:-0} )); then
      blk=$((blk + 1))
    fi
    stmt_block[$i]=$blk
  done

  echo "=== Control flow graph ==="
  echo "platform:  $_INTERCAL_PLATFORM"
  echo "blocks:    $((blk + 1))"
  echo "stmts:     $stmt_count"
  echo

  # Pass 3: emit each block.
  local b
  local -a blk_starts blk_ends
  blk_starts[1]=1
  blk=0
  for (( i=2; i<=stmt_count; i++ )); do
    if (( ${is_leader[$i]:-0} )); then
      blk_ends[$((blk + 1))]=$((i - 1))
      blk=$((blk + 1))
      blk_starts[$((blk + 1))]=$i
    fi
  done
  blk_ends[$((blk + 1))]=$stmt_count
  local total_blocks=$((blk + 1))

  for (( b=1; b<=total_blocks; b++ )); do
    local s=${blk_starts[$b]}
    local e=${blk_ends[$b]}
    local first_label="${stmt_label[$s]:-}"
    local hdr="B$((b - 1)): stmts ${s}..${e}"
    [[ -n "$first_label" ]] && hdr+="  [label ${first_label}]"
    echo "$hdr"
    for (( i=s; i<=e; i++ )); do
      local t="${stmt_type[$i]:-?}"
      local note=""
      (( stmt_polite[$i] )) && note+=" PLEASE"
      (( stmt_negated[$i] )) && note+=" NOT"
      [[ -n "${stmt_label[$i]:-}" ]] && note+=" (label ${stmt_label[$i]})"
      printf "  stmt %3d: %-12s%s\n" "$i" "$t" "$note"
    done

    # Edges from this block: examine the last statement.
    local last="${stmt_type[$e]:-}"
    case "$last" in
      GIVE_UP)
        echo "  -> exit"
        ;;
      NEXT)
        local target="${stmt_next_target[$e]:-}"
        if [[ -n "$target" ]] && [[ -n "${label_to_stmt[$target]:-}" ]]; then
          local target_stmt=${label_to_stmt[$target]}
          local target_blk=${stmt_block[$target_stmt]}
          echo "  -> B${target_blk} (NEXT to label ${target})"
          # Implicit return path is dynamic (RESUME pops); not modelled.
        else
          echo "  -> ??? (NEXT to ${target:-unknown})"
        fi
        ;;
      RESUME)
        echo "  -> dynamic (RESUME pops NEXT stack)"
        ;;
      *)
        # Fall-through. If the last statement has a label that has a
        # COME FROM, control transfers to the COME FROM source after
        # this stmt rather than falling through.
        local last_label="${stmt_label[$e]:-}"
        if [[ -n "$last_label" ]] && [[ -n "${come_from_target[$last_label]:-}" ]]; then
          local cf_stmt=${come_from_target[$last_label]}
          local cf_blk=${stmt_block[$cf_stmt]}
          echo "  -> B${cf_blk} (COME FROM source)"
        elif (( e + 1 <= stmt_count )); then
          local fall_blk=${stmt_block[$((e + 1))]}
          echo "  -> B${fall_blk} (fall-through)"
        else
          echo "  -> exit (fell off end -> E633 at runtime)"
        fi
        ;;
    esac
    echo
  done
}

emit_3addr() {
  # Inspection-only: emit a flat three-address view of each statement.
  # This is conceptually GIMPLE-shaped (Cooper & Torczon ch. 5 / GCC's
  # GIMPLE / LLVM-IR-style) but vastly simpler. The dump is for
  # teaching the IR concept; codegen still walks the parse tree.
  local i
  echo "=== Three-address dump ==="
  echo "platform:  $_INTERCAL_PLATFORM"
  echo "stmts:     $stmt_count"
  echo
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-?}"
    local body="${stmt_body[$i]:-}"
    local lbl="${stmt_label[$i]:-}"
    local prefix="${i}:"
    [[ -n "$lbl" ]] && prefix+="(${lbl})"
    (( stmt_polite[$i] )) && prefix+=" PLEASE"
    (( stmt_negated[$i] )) && prefix+=" NOT"
    case "$t" in
      ASSIGN)
        echo "  ${prefix} ASSIGN  ${body}"
        ;;
      ASSIGN_ARRAY)
        echo "  ${prefix} STORE   ${body}"
        ;;
      ARRAY_DIM)
        echo "  ${prefix} DIM     ${body}"
        ;;
      NEXT)
        echo "  ${prefix} NEXT    -> label ${stmt_next_target[$i]:-?}"
        ;;
      RESUME)
        echo "  ${prefix} RESUME  ${body}"
        ;;
      FORGET)
        echo "  ${prefix} FORGET  ${body}"
        ;;
      ABSTAIN|REINSTATE)
        echo "  ${prefix} ${t}  ${body}"
        ;;
      COME_FROM)
        echo "  ${prefix} COME_FROM <- label ${stmt_cf_target[$i]:-?}"
        ;;
      IGNORE|REMEMBER|STASH|RETRIEVE)
        echo "  ${prefix} ${t}  ${body}"
        ;;
      READ_OUT|WRITE_IN)
        echo "  ${prefix} ${t} ${body}"
        ;;
      GIVE_UP)
        echo "  ${prefix} GIVE_UP"
        ;;
      *)
        echo "  ${prefix} ${t}  ${body}"
        ;;
    esac
  done
}

diagnose() {
  local polite=0 not_count=0
  local -A type_count
  local -A var_used
  local -a labels
  local -a syslib_calls
  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    (( stmt_polite[$i] )) && (( polite++ )) || true
    (( stmt_negated[$i] )) && (( not_count++ )) || true
    local t="${stmt_type[$i]:-?}"
    type_count[$t]=$((${type_count[$t]:-0}+1))
    [[ -n "${stmt_label[$i]:-}" ]] && labels+=("${stmt_label[$i]}")
    if [[ "$t" == "NEXT" ]]; then
      local target="${stmt_next_target[$i]:-}"
      (( target >= 1000 && target <= 1999 )) && syslib_calls+=("$target")
      (( target == 666 )) && syslib_calls+=("666 (Label 666 syscall)")
    fi
  done

  echo "=== INTERCAL compile-time diagnostics ===" >&2
  echo "platform:           $_INTERCAL_PLATFORM" >&2
  echo "statements:         $stmt_count" >&2
  echo "  PLEASE:           $polite" >&2
  echo "  NOT (abstained):  $not_count" >&2
  if (( stmt_count >= 5 )); then
    local pct=$((polite * 100 / stmt_count))
    echo "  politeness ratio: ${pct}%  (must be in [20%, 33%])" >&2
  else
    echo "  politeness:       not enforced (under 5 statements)" >&2
  fi
  echo "labels defined:     ${#labels[@]}" >&2
  echo "syslib calls:       ${#syslib_calls[@]}" >&2
  if (( ${#syslib_calls[@]} > 0 )); then
    local seen
    seen=$(printf "%s\n" "${syslib_calls[@]}" | sort -u | tr '\n' ' ')
    echo "  unique targets:   $seen" >&2
  fi
  echo "needs syslib:       $needs_syslib" >&2
  echo "uses --pure-syslib: $USE_PURE_SYSLIB" >&2
  echo "statement types:" >&2
  for t in "${(@k)type_count}"; do
    printf "  %-12s %d\n" "$t" "${type_count[$t]}" >&2
  done
}

die_compile() {
  local code=$1
  local msg=$2
  # Optional third arg is a statement index for context. Many call sites pass
  # $3 as the current statement index; codegen sites can also rely on $i in
  # scope by passing nothing -- we attempt to detect.
  local ctx_idx="${3:-}"
  if [[ -z "$ctx_idx" && -n "${i:-}" && "$i" =~ '^[0-9]+$' ]]; then
    ctx_idx="$i"
  fi
  echo "ICL${code}I ${msg}" >&2
  if [[ -n "$ctx_idx" && -n "${stmt_type[$ctx_idx]:-}" ]]; then
    local lbl="${stmt_label[$ctx_idx]:-}"
    local line="${stmt_source_line[$ctx_idx]:-?}"
    if [[ -n "$lbl" ]]; then
      echo "    ON THE WAY TO STATEMENT $ctx_idx (LABEL ($lbl), SOURCE LINE $line)" >&2
    else
      echo "    ON THE WAY TO STATEMENT $ctx_idx (SOURCE LINE $line)" >&2
    fi
  fi
  exit 1
}

next_uid() {
  (( unique_id++ )) || true
  REPLY=$unique_id
}

# ============================================================
# SECTION 3: Lexer / Tokenizer
# ============================================================

# Note [DoInclude]
#   Non-standard extension: 'DO INCLUDE "filename"' splices the named
#   file's contents at parse time. Resolution is relative to:
#     1. The current working directory.
#     2. The directory of the file being processed (when known).
#   Cycle detection: a stack of currently-open files; if INCLUDE
#   targets one already on the stack, error out.
#   Label namespace is FLAT: included files share the same label
#   space as the includer; duplicates trigger ICL182 as usual.
#
#   The include syntax is parsed before tokenisation by string-
#   substituting the directive with the file's contents. We treat
#   case-insensitive '"' as the only legal quote (not the rabbit-
#   ears '"'), to keep the syntax distinct from INTERCAL operators.

typeset -a _include_stack
typeset -g _include_result=""
typeset -g _include_error=""

# Walks $1 in-place and writes the expanded text into the global
# _include_result, or sets _include_error on failure. Avoids the
# command-substitution subshell that otherwise eats exit codes.
process_includes() {
  local text="$1"
  local depth=$2
  if (( depth > 32 )); then
    _include_error="ICL197I INCLUDE depth limit (32) exceeded"
    return 1
  fi
  local rest="$text"
  while [[ "$rest" =~ '(.*)DO INCLUDE "([^"]+)"(.*)' ]]; do
    local before="${match[1]}"
    local fname="${match[2]}"
    local after="${match[3]}"
    local s=""
    for s in "${_include_stack[@]}"; do
      if [[ "$s" == "$fname" ]]; then
        _include_error="ICL197I INCLUDE cycle detected: $fname"
        return 1
      fi
    done
    local found=""
    if [[ -f "$fname" ]]; then
      found="$fname"
    elif (( ${#_include_stack[@]} > 0 )) && [[ -f "${_include_stack[-1]:h}/$fname" ]]; then
      found="${_include_stack[-1]:h}/$fname"
    fi
    if [[ -z "$found" ]]; then
      _include_error="ICL197I INCLUDE file not found: $fname"
      return 1
    fi
    _include_stack+=("$found")
    local sub
    sub=$(cat "$found")
    sub=${sub//$'\n'/ }
    sub=${sub//$'\t'/ }
    sub=${sub//$'\r'/ }
    process_includes "$sub" $((depth + 1)) || return 1
    sub="$_include_result"
    _include_stack=("${_include_stack[@]:0:$((${#_include_stack[@]}-1))}")
    rest="${before} ${sub} ${after}"
  done
  _include_result="$rest"
  return 0
}

read_source() {
  local raw
  raw=$(cat)
  raw=${raw//$'\n'/ }
  raw=${raw//$'\t'/ }
  raw=${raw//$'\r'/ }
  # Process DO INCLUDE directives before uppercasing to preserve
  # case-sensitive filenames. Note [DoInclude].
  if ! process_includes "$raw" 0; then
    print -u2 "$_include_error"
    exit 1
  fi
  raw="$_include_result"
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
          if [[ "$nw" == "DO" || "$nw" == "DON'T" || "$nw" == "PLEASE" || "$nw" == "PLSDO" ]]; then
            label="$w"
            (( i++ ))
            w="${words[$i]}"
            is_start=1
          fi
        fi
      fi
    fi

    if [[ "$w" == "DO" || "$w" == "DON'T" || "$w" == "PLEASE" || "$w" == "PLSDO" ]]; then
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

    # Parse identifier (PLSDO, PLEASE, DON'T, DO)
    stmt_polite[$idx]=0
    stmt_negated[$idx]=0
    if [[ "$body" =~ '^PLSDO[[:space:]]*(.*)$' ]]; then
      stmt_polite[$idx]=1
      body="${match[1]}"
    elif [[ "$body" =~ '^PLEASE[[:space:]]*(.*)$' ]]; then
      stmt_polite[$idx]=1
      body="${match[1]}"
    elif [[ "$body" =~ "^DON'T[[:space:]]*(.*)\$" ]]; then
      stmt_polite[$idx]=0
      stmt_negated[$idx]=1
      body="${match[1]}"
    elif [[ "$body" =~ '^DO[[:space:]]*(.*)$' ]]; then
      stmt_polite[$idx]=0
      body="${match[1]}"
    fi

    # Parse negation (NOT or N'T after DO/PLEASE, not DON'T which is handled above)
    if (( ! stmt_negated[$idx] )); then
      if [[ "$body" =~ "^NOT[[:space:]]+(.*)\$" ]]; then
        stmt_negated[$idx]=1
        body="${match[1]}"
      elif [[ "$body" =~ "^N'T[[:space:]]+(.*)\$" ]]; then
        stmt_negated[$idx]=1
        body="${match[1]}"
      fi
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

  stmt_next_from_expr[$idx]=""

  if [[ "$body" == "GIVE UP" ]]; then
    stmt_type[$idx]="GIVE_UP"
  elif [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]*NEXT[[:space:]]+FROM[[:space:]]+(.+)$' ]]; then
    # NEXT FROM extension: (LABEL) NEXT FROM <expr>  -- conditional
    # backward branch (jumps if bit 0 of <expr> is set), no NEXT-stack
    # push. See docs/loop-extension.md.
    stmt_type[$idx]="NEXT_FROM"
    stmt_next_target[$idx]="${match[1]}"
    stmt_next_from_expr[$idx]="${match[2]}"
  elif [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]*NEXT[[:space:]]+FROM$' ]]; then
    # NEXT FROM extension: (LABEL) NEXT FROM  -- unconditional jump.
    stmt_type[$idx]="NEXT_FROM"
    stmt_next_target[$idx]="${match[1]}"
    stmt_next_from_expr[$idx]=""
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

# Note [PoliteRatioBoundary]
#   The INTERCAL-72 manual specifies that "no fewer than 1/5 nor more
#   than 1/3" of statements must use PLEASE. We compute integer-only
#   ratios via cross-multiplication:
#     polite/total >= 1/5  iff  5*polite >= total  iff  polite*5 >= total
#     polite/total <= 1/3  iff  3*polite <= total  iff  polite*3 <= total
#   Boundaries: under 5 statements the rule does not apply (the
#   INTERCAL-72 spec is silent for very small programs; we exempt them
#   as a convenience). The lower bound uses strict "less" so a program
#   with exactly 1/5 polite statements passes. The upper bound uses
#   strict "greater" so 1/3 is the inclusive ceiling.
check_politeness() {
  if (( stmt_count < 5 )); then return; fi
  local polite=0
  local i=""
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
  local i=""
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

# Note [UnreferencedLabelWarning]
#   Per AGENTS.md, ICLnnnW is the warning convention (vs ICLnnnI for
#   fatal errors). After resolve_come_from we walk every labelled
#   statement and check whether any other statement targets it via
#   NEXT, ABSTAIN/REINSTATE (label form), or COME FROM. Labels with
#   no static reference are warned about. The check is conservative
#   for ABSTAIN/REINSTATE on gerunds: those affect statement TYPES,
#   not individual labels, so they do not count as "referencing" a
#   label. Same for syslib labels (1000-1999): they are external by
#   convention and not warned.
#   We use ICL197W as the warning code (W variant of E197 LABEL
#   VALUE OUTSIDE PERMITTED RANGE; the 197 family is label-related).
check_unreferenced_labels() {
  local i
  typeset -A label_referenced
  # Walk all statements collecting label references.
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-}"
    case "$t" in
      NEXT|NEXT_FROM)
        local target="${stmt_next_target[$i]:-}"
        [[ -n "$target" ]] && label_referenced[$target]=1
        ;;
      COME_FROM)
        local target="${stmt_cf_target[$i]:-}"
        [[ -n "$target" ]] && label_referenced[$target]=1
        ;;
      ABSTAIN|REINSTATE)
        local body="${stmt_body[$i]:-}"
        # Single-label form: ABSTAIN FROM (NN) or REINSTATE (NN)
        if [[ "$body" =~ \(([0-9]+)\) ]]; then
          label_referenced[${match[1]}]=1
        fi
        ;;
    esac
  done
  # Walk labelled statements; warn on unreferenced ones.
  for (( i=1; i<=stmt_count; i++ )); do
    local lbl="${stmt_label[$i]:-}"
    [[ -z "$lbl" ]] && continue
    # Syslib range is treated as externally callable; skip.
    if (( lbl >= 1000 && lbl <= 1999 )); then continue; fi
    if (( ! ${+label_referenced[$lbl]} )); then
      print -u2 "ICL197W LABEL ${lbl} IS UNREFERENCED"
    fi
  done
}

# Note [ComeFromUnique]
#   INTERCAL's COME FROM creates an implicit edge from a labelled
#   statement to the COME FROM source: after the labelled statement
#   executes, control transfers to the COME FROM site rather than
#   falling through. The INTERCAL-72 spec allows at most one COME FROM
#   per target label; multiple targets cause E555 at compile time.
#   This is the only check we do here; codegen later inserts the
#   implicit edge by emitting an unconditional branch at the end of
#   the labelled statement to the COME FROM source.
#   Note that COME FROM was not in the original INTERCAL-72 spec; we
#   adopted it as a standard feature per modern INTERCAL practice.
resolve_come_from() {
  local i=""
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
  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    if [[ "${stmt_type[$i]}" == "NEXT" ]]; then
      local target="${stmt_next_target[$i]}"
      if (( target >= 1000 && target <= 1999 )); then
        needs_syslib=1
        # With --pure-syslib, syslib labels come from syslib.i appended
        # to the source (regular INTERCAL statement numbering applies).
        # With --emit-syslib, we ARE compiling syslib.i, so its self-
        # references should resolve to its own internal _stmt_K labels
        # rather than the external _rt_syslib_NNNN entry-point alias.
        # Otherwise (default user build): map syslib labels to the
        # external _rt_syslib_NNNN symbols provided by the syslib lib.
        if (( ! USE_PURE_SYSLIB && ! EMIT_SYSLIB_MODE )); then
          label_to_stmt[$target]="syslib_${target}"
        fi
      fi
      if (( target == 666 )); then
        label_to_stmt[666]="syscall_666"
        # Reserve ,65535 for syscall buffer
        used_tail[65535]=1
      fi
    fi
  done

  # Always ensure syslib/runtime interface vars exist (runtime.s references them)
  used_spot[1]=1; used_spot[2]=1; used_spot[3]=1; used_spot[4]=1; used_spot[5]=1
  used_twospot[1]=1; used_twospot[2]=1; used_twospot[3]=1; used_twospot[4]=1
  # Label 666 syscall buffer (always in runtime.s)
  used_tail[65535]=1
}

# Mark which statements need a runtime abstain/reinstate flag check.
# A stmt is "modifiable" if it is initially abstained (DON'T) OR if any
# ABSTAIN/REINSTATE statement targets it (by label or by gerund).
# Statements that are never modified can skip the 4-instruction flag
# load at their entry point: dead-flag elimination.
# Note [VarConstantProp]
#   Cross-statement constant propagation: if a variable is assigned
#   only with literal #N values and never modified by IGNORE/REMEMBER/
#   STASH/RETRIEVE/ABSTAIN-on-CALCULATING, we record its value in
#   var_const[VARSPEC] and codegen_expr substitutes the literal at
#   read sites instead of emitting a load.
#
#   This is a simpler, monotonically-conservative variant of SCCP:
#   - The first ASSIGN of #N to a var sets var_const[var] = N.
#   - Any subsequent ASSIGN of a non-literal, OR any read by WRITE_IN,
#     OR any reachable RETRIEVE, makes var_const[var] = BOTTOM (drop).
#   - At each codegen_expr call to read .V, we look up the per-stmt
#     value (computed at the corresponding statement). For simplicity
#     we record the var_const state at the START of each statement;
#     later use sites in the same statement see this snapshot.
typeset -A var_const
typeset -A stmt_var_const   # stmt_index|varname -> value at start of stmt

compute_var_constants() {
  var_const=()
  stmt_var_const=()
  local i
  local -A var_bottom
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-}"
    local body="${stmt_body[$i]:-}"
    case "$t" in
      WRITE_IN)
        local items="${body#WRITE IN }"
        for tok in ${=items}; do
          tok="${tok## }"; tok="${tok%% }"; [[ -z "$tok" ]] && continue
          if [[ "$tok" =~ '^\.([0-9]+)$' ]]; then
            var_bottom[spot_${match[1]}]=1
          elif [[ "$tok" =~ '^:([0-9]+)$' ]]; then
            var_bottom[twospot_${match[1]}]=1
          fi
        done
        ;;
      RETRIEVE|STASH)
        local items="${body#RETRIEVE }"; items="${items#STASH }"
        for tok in ${=items}; do
          tok="${tok## }"; tok="${tok%% }"; [[ -z "$tok" ]] && continue
          if [[ "$tok" =~ '^\.([0-9]+)$' ]]; then
            var_bottom[spot_${match[1]}]=1
          elif [[ "$tok" =~ '^:([0-9]+)$' ]]; then
            var_bottom[twospot_${match[1]}]=1
          fi
        done
        ;;
      ASSIGN)
        local target="${body%%<-*}"; target="${target## }"; target="${target%% }"
        local rhs="${body#*<-}"; rhs="${rhs## }"; rhs="${rhs%% }"
        # Note [VarConstantProp]: track "linkable" RHS forms.
        # A target is BOTTOM only if its RHS is neither a literal
        # #N nor a simple var-to-var (.Y / :Y) copy. This admits
        # chain copies through the forward pass.
        local rhs_linkable=0
        if [[ "$rhs" =~ '^#([0-9]+)$' ]]; then
          rhs_linkable=1
        elif [[ "$rhs" =~ '^[\.:][0-9]+$' ]]; then
          rhs_linkable=1
        fi
        if (( ! rhs_linkable )); then
          if [[ "$target" =~ '^\.([0-9]+)$' ]]; then
            var_bottom[spot_${match[1]}]=1
          elif [[ "$target" =~ '^:([0-9]+)$' ]]; then
            var_bottom[twospot_${match[1]}]=1
          fi
        fi
        ;;
      ABSTAIN|REINSTATE)
        if [[ "$body" == *CALCULATING* ]]; then
          typeset -g var_const_disabled=1
          return
        fi
        # ABSTAIN FROM (label) form: mark the target statement's
        # assigned variable as BOTTOM so we do not propagate its
        # value through (it may not run at all).
        if [[ "$body" =~ \(([0-9]+)\) ]]; then
          local lbl="${match[1]}"
          local ts="${label_to_stmt[$lbl]:-}"
          if [[ -n "$ts" && "$ts" != syslib_* && "$ts" != syscall_666 ]]; then
            local tt="${stmt_type[$ts]:-}"
            if [[ "$tt" == "ASSIGN" ]]; then
              local tb="${stmt_body[$ts]:-}"
              local ttarget="${tb%%<-*}"; ttarget="${ttarget## }"; ttarget="${ttarget%% }"
              if [[ "$ttarget" =~ '^\.([0-9]+)$' ]]; then
                var_bottom[spot_${match[1]}]=1
              elif [[ "$ttarget" =~ '^:([0-9]+)$' ]]; then
                var_bottom[twospot_${match[1]}]=1
              fi
            fi
          fi
        fi
        ;;
      COME_FROM)
        # COME FROM creates an implicit re-entry; defs across the
        # come-from edge cannot be propagated reliably. Mark all
        # currently-assigned vars BOTTOM by disabling globally.
        typeset -g var_const_disabled=1
        return
        ;;
      NEXT)
        # NEXT to non-syslib transfers control somewhere; the
        # destination may modify state we do not track. Conservative:
        # disable globally.
        local target="${stmt_next_target[$i]:-}"
        if [[ -n "$target" ]] && (( target < 1000 || target > 1999 )); then
          typeset -g var_const_disabled=1
          return
        fi
        ;;
      NEXT_FROM)
        # NEXT FROM is a backward branch: defs reaching the target may
        # be from this point or from before the target's definition.
        # Conservative: disable.
        typeset -g var_const_disabled=1
        return
        ;;
    esac
  done
  typeset -g var_const_disabled=0
  local -A current_const
  local k=""
  for (( i=1; i<=stmt_count; i++ )); do
    for k in "${(@k)current_const}"; do
      stmt_var_const[${i}:${k}]="${current_const[$k]}"
    done
    local t="${stmt_type[$i]:-}"
    [[ "$t" != "ASSIGN" ]] && continue
    local body="${stmt_body[$i]:-}"
    local target="${body%%<-*}"; target="${target## }"; target="${target%% }"
    local rhs="${body#*<-}"; rhs="${rhs## }"; rhs="${rhs%% }"
    local val=""
    if [[ "$rhs" =~ '^#([0-9]+)$' ]]; then
      val="${match[1]}"
    elif [[ "$rhs" =~ '^\.([0-9]+)$' ]]; then
      # Var-to-var copy: read source's current constant value.
      val="${current_const[spot_${match[1]}]:-}"
    elif [[ "$rhs" =~ '^:([0-9]+)$' ]]; then
      val="${current_const[twospot_${match[1]}]:-}"
    fi
    if [[ -n "$val" ]]; then
      if [[ "$target" =~ '^\.([0-9]+)$' ]]; then
        local vk="spot_${match[1]}"
        if (( ! ${+var_bottom[$vk]} )); then
          current_const[$vk]=$val
        fi
      elif [[ "$target" =~ '^:([0-9]+)$' ]]; then
        local vk="twospot_${match[1]}"
        if (( ! ${+var_bottom[$vk]} )); then
          current_const[$vk]=$val
        fi
      fi
    fi
  done
}

# Note [E275Elim]
#   Per-statement static check: an ASSIGN of a #N constant where N
#   is in [0, 65535] for spot or [0, 4294967295] for twospot CANNOT
#   raise E275. We pre-compute stmt_e275_safe[i] for those cases and
#   codegen_assign skips the cmp+b.hi check. Each elision is gated
#   by opt_bisect_check so --opt-bisect-limit can disable it.
#   Conservative: anything other than a literal #N is treated as
#   maybe-overflow.
typeset -A stmt_e275_safe
typeset -A stmt_e621_safe   # RESUME #N where N != 0 cannot raise E621
typeset -A stmt_e436_safe   # RETRIEVE preceded by sufficient STASH on every path

compute_e275_safety() {
  stmt_e275_safe=()
  stmt_e621_safe=()
  stmt_e436_safe=()
  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]:-}"
    local body="${stmt_body[$i]:-}"
    case "$t" in
      ASSIGN)
        local target="${body%%<-*}"; target="${target## }"; target="${target%% }"
        local rhs="${body#*<-}"; rhs="${rhs## }"; rhs="${rhs%% }"
        local r="$rhs"; r="${r## }"; r="${r%% }"
        if [[ "$r" =~ '^#([0-9]+)$' ]]; then
          local val="${match[1]}"
          if [[ "$target" =~ '^\.[0-9]+$' ]]; then
            (( val <= 65535 )) && stmt_e275_safe[$i]=1
          elif [[ "$target" =~ '^:[0-9]+$' ]]; then
            (( val <= 4294967295 )) && stmt_e275_safe[$i]=1
          fi
        fi
        # Var-to-var copy: target type matches source type, so no
        # widening overflow possible (caller still checks the runtime
        # path for safety).
        if [[ "$r" =~ '^\.[0-9]+$' ]] && [[ "$target" =~ '^\.[0-9]+$' ]]; then
          stmt_e275_safe[$i]=1
        fi
        if [[ "$r" =~ '^:[0-9]+$' ]] && [[ "$target" =~ '^:[0-9]+$' ]]; then
          stmt_e275_safe[$i]=1
        fi
        ;;
      RESUME)
        # RESUME #N where N is a literal nonzero -> E621 unreachable.
        local arg="${body#RESUME }"
        arg="${arg## }"; arg="${arg%% }"
        if [[ "$arg" =~ '^#([0-9]+)$' ]] && (( ${match[1]} != 0 )); then
          stmt_e621_safe[$i]=1
        fi
        ;;
      RETRIEVE)
        # RETRIEVE is safe (E436 unreachable) when a preceding STASH
        # of the same vars is statically guaranteed on every path.
        # Conservative: require an unconditional STASH of the same
        # var-list earlier in the statement sequence, with no
        # intervening RETRIEVE of the same vars and no NEXT or
        # COME FROM that could divert away from the STASH.
        local items="${body#RETRIEVE }"; items="${items## }"
        local all_safe=1
        for tok in ${=items}; do
          tok="${tok## }"; tok="${tok%% }"; [[ -z "$tok" ]] && continue
          local found=0
          local j=0
          for (( j=i-1; j>=1; j-- )); do
            local jt="${stmt_type[$j]:-}"
            local jb="${stmt_body[$j]:-}"
            if [[ "$jt" == "STASH" ]] && [[ "$jb" == *"$tok"* ]]; then
              # Verify no abstain on this STASH and no diverting flow.
              if (( ! stmt_negated[$j] )) && (( ! stmt_needs_flag[$j] )); then
                found=1
              fi
              break
            fi
            # Conservative stoppers: NEXT, RESUME, COME FROM, GIVE UP
            case "$jt" in
              NEXT|NEXT_FROM|RESUME|GIVE_UP|COME_FROM)
                break
                ;;
            esac
          done
          (( found )) || { all_safe=0; break; }
        done
        (( all_safe )) && stmt_e436_safe[$i]=1
        ;;
    esac
  done
}

# Note [IgnoreDCE]
#   var_needs_ign[VARSPEC] = 1 if the program contains an IGNORE or
#   REMEMBER statement referencing VARSPEC (spot_N, twospot_N, tail_N,
#   hybrid_N). Variables not in the set are never IGNOREd, so the
#   per-assignment runtime _ign-flag check is dead code and codegen
#   skips it. See proposal 6 in docs/improvement-proposals.md.
typeset -A var_needs_ign

compute_ignore_checks() {
  var_needs_ign=()
  # Also flag everything if a gerund-based ABSTAIN/REINSTATE on
  # IGNORING or REMEMBERING is present: the analysis cannot tell
  # which specific variables become target without flow-sensitive
  # data. Conservative: keep all checks. (This rarely matters in
  # practice; gerund-based abstain on IGNORING is uncommon.)
  local i
  local conservative=0
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]}"
    if [[ "$t" == "ABSTAIN" || "$t" == "REINSTATE" ]]; then
      local body="${stmt_body[$i]}"
      if [[ "$body" == *IGNORING* || "$body" == *REMEMBERING* ]]; then
        conservative=1
      fi
    fi
  done
  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]}"
    [[ "$t" != "IGNORE" && "$t" != "REMEMBER" ]] && continue
    local body="${stmt_body[$i]}"
    local items="${body#IGNORE }"
    items="${items#REMEMBER }"
    local -a var_list
    parse_var_list "$items"
    for item in "${var_list[@]}"; do
      item="${item## }"
      item="${item%% }"
      if [[ "$item" =~ '^\.([0-9]+)$' ]]; then
        var_needs_ign[spot_${match[1]}]=1
      elif [[ "$item" =~ '^:([0-9]+)$' ]]; then
        var_needs_ign[twospot_${match[1]}]=1
      elif [[ "$item" =~ '^,([0-9]+)$' ]]; then
        var_needs_ign[tail_${match[1]}]=1
      elif [[ "$item" =~ '^;([0-9]+)$' ]]; then
        var_needs_ign[hybrid_${match[1]}]=1
      fi
    done
  done
  # If conservative, mark every observed variable. We don't have a
  # full variable list ahead of codegen, so the simpler conservative
  # path is to disable the optimisation: var_needs_ign_any=1 acts as
  # a global override consulted by codegen.
  if (( conservative )); then
    typeset -g var_needs_ign_any=1
  else
    typeset -g var_needs_ign_any=0
  fi
}

typeset -a stmt_needs_flag
compute_flag_checks() {
  local i j
  # Default: every statement starts with needs_flag=1 (always check,
  # the conservative answer). The optimisation below clears it for
  # statements proven never to be modified. Each clearance is gated
  # by opt_bisect_check so --opt-bisect-limit=0 retains every check.
  for (( i=1; i<=stmt_count; i++ )); do
    stmt_needs_flag[$i]=1
  done
  for (( i=1; i<=stmt_count; i++ )); do
    if (( stmt_negated[$i] )); then
      continue
    fi
    if opt_bisect_check "dead_flag_check_stmt_$i"; then
      stmt_needs_flag[$i]=0
    fi
  done

  # Map gerund tokens to statement types.
  local -A gerund_to_type
  gerund_to_type[CALCULATING]="ASSIGN ARRAY_DIM"
  gerund_to_type[NEXTING]="NEXT"
  gerund_to_type[FORGETTING]="FORGET"
  gerund_to_type[RESUMING]="RESUME"
  gerund_to_type[STASHING]="STASH"
  gerund_to_type[RETRIEVING]="RETRIEVE"
  gerund_to_type[IGNORING]="IGNORE"
  gerund_to_type[REMEMBERING]="REMEMBER"
  gerund_to_type[ABSTAINING]="ABSTAIN"
  gerund_to_type[REINSTATING]="REINSTATE"
  gerund_to_type[COMINGFROM]="COME_FROM"
  gerund_to_type[READINGOUT]="READ_OUT"
  gerund_to_type[WRITINGIN]="WRITE_IN"

  for (( i=1; i<=stmt_count; i++ )); do
    local t="${stmt_type[$i]}"
    [[ "$t" != "ABSTAIN" && "$t" != "REINSTATE" ]] && continue
    local body="${stmt_body[$i]}"
    local flag_arg=""
    if [[ "$t" == "ABSTAIN" ]]; then
      flag_arg="${body#ABSTAIN FROM }"
    else
      flag_arg="${body#REINSTATE }"
    fi
    flag_arg="${flag_arg## }"
    if [[ "$flag_arg" == \(*\) ]]; then
      local target_label="${flag_arg#\(}"
      target_label="${target_label%\)}"
      local target_stmt="${label_to_stmt[$target_label]:-}"
      [[ -z "$target_stmt" || "$target_stmt" == syslib_* || "$target_stmt" == syscall_666 ]] && continue
      stmt_needs_flag[$target_stmt]=1
    else
      # Gerund list. Normalize multi-word gerunds the same way codegen does.
      local text="$flag_arg"
      text="${text/COMING FROM/COMINGFROM}"
      text="${text/READING OUT/READINGOUT}"
      text="${text/WRITING IN/WRITINGIN}"
      local -a gerunds
      gerunds=(${=text})
      for g in "${gerunds[@]}"; do
        local types="${gerund_to_type[$g]:-}"
        [[ -z "$types" ]] && continue
        for (( j=1; j<=stmt_count; j++ )); do
          for tt in ${=types}; do
            [[ "${stmt_type[$j]}" == "$tt" ]] && stmt_needs_flag[$j]=1
          done
        done
      done
    fi
  done
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
    # Spark/rabbit-ears must alternate: ' inside " or " inside ', never same-in-same.
    # group_char passed to us is the EXPECTED inner grouping char from our caller.
    # If we see something different, the user nested same-in-same.
    if [[ -n "$group_char" && "$open" != "$group_char" ]]; then
      local quote_name="spark"
      [[ "$open" == '"' ]] && quote_name="rabbit-ears"
      die_compile "017" "DO YOU EXPECT ME TO FIGURE THIS OUT? (NESTED $quote_name INSIDE $quote_name; alternate with the other)"
    fi
    (( parse_pos++ ))

    # Determine inner grouping char
    local inner_group=""
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

# eval_const(id) - if the expression at $id is a pure constant (no
# variables, no array refs), echo its value; else echo "". 16-bit and
# 32-bit unary AND/OR/XOR, mingle, and select are all folded.
eval_const() {
  local id=$1
  local t="${expr_type[$id]}"
  case "$t" in
    CONST)
      echo "${expr_val[$id]}"
      ;;
    OP_AND|OP_OR|OP_XOR)
      local cv=""
      cv=$(eval_const "${expr_child[$id]}")
      [[ -z "$cv" ]] && return
      local w=${expr_width[$id]}
      local mask=0 rot=0
      if (( w == 32 )); then
        mask=$((0xFFFFFFFF))
        # rotate right 1 bit in 32-bit
        rot=$(( ((cv >> 1) | ((cv & 1) << 31)) & mask ))
      else
        mask=$((0xFFFF))
        rot=$(( ((cv >> 1) | ((cv & 1) << 15)) & mask ))
      fi
      case "$t" in
        OP_AND) echo $(( (cv & rot) & mask )) ;;
        OP_OR)  echo $(( (cv | rot) & mask )) ;;
        OP_XOR) echo $(( (cv ^ rot) & mask )) ;;
      esac
      ;;
    OP_MINGLE)
      local lv="" rv=""
      lv=$(eval_const "${expr_left[$id]}")
      [[ -z "$lv" ]] && return
      rv=$(eval_const "${expr_right[$id]}")
      [[ -z "$rv" ]] && return
      local result=0 i=0
      for (( i=0; i<16; i++ )); do
        local bit_l=$(( (lv >> i) & 1 ))
        local bit_r=$(( (rv >> i) & 1 ))
        result=$(( result | (bit_l << (2*i + 1)) | (bit_r << (2*i)) ))
      done
      echo "$result"
      ;;
    OP_SELECT)
      local lv="" rv=""
      lv=$(eval_const "${expr_left[$id]}")
      [[ -z "$lv" ]] && return
      rv=$(eval_const "${expr_right[$id]}")
      [[ -z "$rv" ]] && return
      # Pack bits of lv at positions where rv has 1, right-justified.
      local result=0 out_pos=0 i=0
      local lw=${expr_width[${expr_left[$id]}]}
      local rw=${expr_width[${expr_right[$id]}]}
      local bits=$(( lw > rw ? lw : rw ))
      for (( i=0; i<bits; i++ )); do
        if (( (rv >> i) & 1 )); then
          local bit_l=$(( (lv >> i) & 1 ))
          result=$(( result | (bit_l << out_pos) ))
          out_pos=$(( out_pos + 1 ))
        fi
      done
      echo "$result"
      ;;
  esac
}

codegen_expr() {
  local id=$1
  local type="${expr_type[$id]}"

  # Constant folding: if the whole subtree evaluates to a literal,
  # emit a single mov instead of recursing into runtime calls.
  case "$type" in
    OP_AND|OP_OR|OP_XOR|OP_MINGLE|OP_SELECT)
      local cval=""
      cval=$(eval_const "$id")
      if [[ -n "$cval" ]]; then
        if (( cval <= 65535 )); then
          emit "  mov w0, #${cval}"
        else
          emit "  movz w0, #$((cval & 0xFFFF))"
          emit "  movk w0, #$((cval >> 16)), lsl #16"
        fi
        return
      fi
      ;;
  esac

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
      # Note [VarConstantProp]: substitute literal if SCCP-style
      # analysis proved this var is a known constant at the start
      # of the current statement.
      local key="${current_stmt_idx:-0}:spot_${num}"
      if (( ! ${var_const_disabled:-0} )) \
         && (( ${+stmt_var_const[$key]} )) \
         && opt_bisect_check "constprop_spot_${num}_at_${current_stmt_idx:-0}"; then
        emit "  mov w0, #${stmt_var_const[$key]}"
      else
        emit "  adrp x1, _spot_${num}@PAGE"
        emit "  add x1, x1, _spot_${num}@PAGEOFF"
        emit "  ldr w0, [x1]"
      fi
      ;;
    VAR_TWOSPOT)
      local num=${expr_val[$id]}
      local key="${current_stmt_idx:-0}:twospot_${num}"
      if (( ! ${var_const_disabled:-0} )) \
         && (( ${+stmt_var_const[$key]} )) \
         && opt_bisect_check "constprop_twospot_${num}_at_${current_stmt_idx:-0}"; then
        emit "  mov w0, #${stmt_var_const[$key]}"
      else
        emit "  adrp x1, _twospot_${num}@PAGE"
        emit "  add x1, x1, _twospot_${num}@PAGEOFF"
        emit "  ldr w0, [x1]"
      fi
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
    local s=""
    for s in "${sub_ids[@]}"; do
      codegen_expr $s
      emit "  str w0, [sp, #-16]!"
    done
    # Now compute linear index: ((s1-1)*d2 + (s2-1))*d3 + ... + (sn-1)
    emit "  mov w0, #0"  # accumulated index
    local j=""
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
  if (( ! EMIT_SYSLIB_MODE )); then
    emit ".global _main"
  fi
  emit ".align 2"
  emit ""
  if (( ! EMIT_SYSLIB_MODE )); then
    emit "_main:"
    emit "  stp x29, x30, [sp, #-16]!"
    emit "  mov x29, sp"
    emit "  // Save argc/argv for Label 666"
    emit "  adrp x2, _rt_argc@PAGE"
    emit "  add x2, x2, _rt_argc@PAGEOFF"
    emit "  str w0, [x2]"
    emit "  adrp x2, _rt_argv@PAGE"
    emit "  add x2, x2, _rt_argv@PAGEOFF"
    emit "  str x1, [x2]"
    emit ""
  fi

  if [[ "${INTERCAL_NEW_IR:-0}" == "1" ]]; then
    build_ir
  fi

  if [[ "${INTERCAL_REGALLOC_HINTS:-0}" == "1" ]]; then
    compute_regalloc_decisions
  fi

  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    codegen_statement $i
  done

  if (( ! EMIT_SYSLIB_MODE )); then
    emit "  b _rt_error_E633"
  fi
  emit ""

  if (( EMIT_SYSLIB_MODE )); then
    # Emit only the per-statement abstain-flag array, renamed to syslib
    # namespace by the post-process pass. Variable BSS is shared with
    # user code and must NOT be emitted here (would conflict at link).
    emit_stmt_flags_only
  else
    emit_data
  fi
}

codegen_statement() {
  local i=$1
  # Note [VarConstantProp]: track current stmt for codegen_expr's
  # VAR_SPOT/VAR_TWOSPOT lookups in stmt_var_const.
  typeset -g current_stmt_idx=$i
  emit ""
  emit "_stmt_${i}:  // ${stmt_type[$i]}"

  # Abstain check (skip if static analysis proves this stmt is never modified).
  if (( ${stmt_needs_flag[$i]:-1} )); then
    local flag_offset=$((i-1))
    emit "  adrp x0, _stmt_flags@PAGE"
    emit "  add x0, x0, _stmt_flags@PAGEOFF"
    if (( flag_offset > 4095 )); then
      emit "  mov w9, #${flag_offset}"
      emit "  ldrb w1, [x0, x9]"
    else
      emit "  ldrb w1, [x0, #${flag_offset}]"
    fi
    emit "  tbnz w1, #0, _stmt_${i}_end"
  fi

  # Probability check
  if (( stmt_prob[$i] < 100 )); then
    codegen_probability $i
  fi

  # Note [NewIROptIn]
  #   When INTERCAL_NEW_IR=1 is set, the IR-driven lowering path is
  #   tried first for the statement types it supports (currently:
  #   GIVE_UP). lower_ir_for_stmt returns 0 (success) if it handled
  #   the statement; non-zero means fall through to the legacy
  #   tree-walk codegen below. This is the incremental migration
  #   scaffold for proposal #11 in docs/improvement-proposals.md.
  #   The flag must never be on by default; the legacy path remains
  #   the source of truth until migration completes.
  local lowered_via_ir=0
  if [[ "${INTERCAL_NEW_IR:-0}" == "1" ]] && lower_ir_for_stmt $i; then
    lowered_via_ir=1
  fi

  if (( ! lowered_via_ir )); then
  case "${stmt_type[$i]}" in
    GIVE_UP)    codegen_give_up ;;
    READ_OUT)   codegen_read_out $i ;;
    WRITE_IN)   codegen_write_in $i ;;
    ASSIGN)     codegen_assign $i ;;
    ARRAY_DIM)  codegen_array_dim $i ;;
    NEXT)       codegen_next $i ;;
    NEXT_FROM)  codegen_next_from $i ;;
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
  fi

  emit "_stmt_${i}_end:"

  # COME FROM redirect
  local lbl="${stmt_label[$i]}"
  if [[ -n "$lbl" ]] && [[ -n "${come_from_target[$lbl]:-}" ]]; then
    local cf_stmt=${come_from_target[$lbl]}
    local cf_offset=$((cf_stmt-1))
    emit "  adrp x0, _stmt_flags@PAGE"
    emit "  add x0, x0, _stmt_flags@PAGEOFF"
    if (( cf_offset > 4095 )); then
      emit "  mov w9, #${cf_offset}"
      emit "  ldrb w1, [x0, x9]"
    else
      emit "  ldrb w1, [x0, #${cf_offset}]"
    fi
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
  # Split variable list into items
  # Items are variables, constants, or array refs with SUB subscripts
  # Array refs like ",1 SUB #2 SUB #3" must stay as one item
  local -a words
  words=(${=text})
  local current=""
  local in_sub=0
  local i=1
  local nw=${#words[@]}
  while (( i <= nw )); do
    local w="${words[$i]}"
    if [[ "$w" == "SUB" ]]; then
      current+=" SUB"
      in_sub=1
    elif (( in_sub )) && [[ "$w" =~ '^[#.:]' ]]; then
      # SUB subscript value (constant or variable)
      current+=" $w"
      # Check if next word is SUB (more subscripts)
      if (( i + 1 <= nw )) && [[ "${words[$((i+1))]}" == "SUB" ]]; then
        in_sub=1
      else
        in_sub=0
      fi
    elif [[ "$w" =~ "^[.,:;#'\"&V?]" ]] || [[ "$w" =~ '^\(' ]]; then
      # New item starts
      if [[ -n "$current" ]]; then
        var_list+=("$current")
      fi
      current="$w"
      in_sub=0
    else
      current+=" $w"
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
    # Note [RegallocHint]: comment-only emission of regalloc decision.
    if [[ "${INTERCAL_REGALLOC_HINTS:-0}" == "1" ]]; then
      local _vk="spot_${vnum}"
      if [[ -n "${var_reg[$_vk]:-}" ]]; then
        emit "  // regalloc: ${_vk} -> ${var_reg[$_vk]}"
      elif (( ${+var_spilled[$_vk]} )); then
        emit "  // regalloc: ${_vk} spilled"
      fi
    fi
    # Note [E275Elim]: skip the cmp+b.hi when the static analysis
    # proves the RHS cannot exceed 65535 (e.g., literal small const).
    local emit_e275_check=1
    if (( ${+stmt_e275_safe[$i]} )) && opt_bisect_check "elim_e275_stmt_$i"; then
      emit_e275_check=0
    fi
    if (( emit_e275_check )); then
      emit "  mov w1, #65535"
      emit "  cmp w0, w1"
      emit "  b.hi _rt_error_E275"
    fi
    # Note [IgnoreDCE]: skip the runtime _ign load+test when the
    # program never IGNOREs this variable. compute_ignore_checks
    # populates var_needs_ign; var_needs_ign_any forces the safe
    # path when ABSTAIN/REINSTATE on IGNORING is present.
    local needs_ign=0
    if (( var_needs_ign_any )) || (( ${+var_needs_ign[spot_${vnum}]} )); then
      needs_ign=1
    fi
    if (( needs_ign )); then
      emit "  adrp x1, _spot_${vnum}_ign@PAGE"
      emit "  add x1, x1, _spot_${vnum}_ign@PAGEOFF"
      emit "  ldrb w2, [x1]"
      emit "  cbnz w2, _stmt_${i}_end"
    fi
    emit "  adrp x1, _spot_${vnum}@PAGE"
    emit "  add x1, x1, _spot_${vnum}@PAGEOFF"
    emit "  str w0, [x1]"
  elif [[ "$target" =~ '^:[0-9]+$' ]]; then
    local vnum="${target#:}"
    local needs_ign=0
    if (( var_needs_ign_any )) || (( ${+var_needs_ign[twospot_${vnum}]} )); then
      needs_ign=1
    fi
    if (( needs_ign )); then
      emit "  adrp x1, _twospot_${vnum}_ign@PAGE"
      emit "  add x1, x1, _twospot_${vnum}_ign@PAGEOFF"
      emit "  ldrb w2, [x1]"
      emit "  cbnz w2, _stmt_${i}_end"
    fi
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
    local j=""
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
  # Target the existing _stmt_N_end label directly; the aedone trampoline
  # added a label that was always at the same address as _end.
  emit "  b _stmt_${i}_end"
  emit "_stmt_${i}_aeskip:"
  emit "  add sp, sp, #16"  # discard value
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
  local d=""
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
  local j=""
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
    die_compile "129" "PROGRAM HAS GOTTEN LOST (NEXT to undefined label ($target_label))"
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

  # Note [InlineSyslibPrimitives]
  #   For short, hot syslib routines we emit the body inline at the
  #   call site instead of 'b _rt_syslib_NNNN'. The pattern is
  #   sound when:
  #     - the routine has no internal NEXT/RESUME/STASH calls,
  #     - it does not depend on the abstain flag (syslib_native skips
  #       abstain checks anyway),
  #     - its register clobbers stay within scratch (x0..x7).
  #   syslib 1020 (in-place increment of .1) satisfies all of these.
  #   The inline form skips the runtime's 'b _rt_resume_1' tail,
  #   replacing the NEXT-stack push above with a no-op (we still pop
  #   in the implied RESUME #1 that ends the syslib via _stmt_X_end).
  #   ARM64 only; x86-64 codegen is handled in codegen_x86_64.sh.
  if [[ "$target_ref" == "syscall_666" ]]; then
    emit "  b _rt_syscall_666"
  elif [[ "$target_ref" == syslib_* ]]; then
    local syslib_num="${target_ref#syslib_}"
    if [[ "$_INTERCAL_PLATFORM" != "linux_x86_64" ]] \
       && [[ "$syslib_num" == "1020" ]] \
       && opt_bisect_check "inline_syslib_1020"; then
      # Inline body: increment .1 in place (16-bit wrap).
      emit "  // inline syslib 1020"
      emit "  adrp x0, _spot_1@PAGE"
      emit "  add x0, x0, _spot_1@PAGEOFF"
      emit "  ldr w1, [x0]"
      emit "  add w1, w1, #1"
      emit "  and w1, w1, #0xFFFF"
      emit "  str w1, [x0]"
      # Pop the NEXT stack (we pushed above as if calling).
      emit "  adrp x0, _next_sp@PAGE"
      emit "  add x0, x0, _next_sp@PAGEOFF"
      emit "  ldr w1, [x0]"
      emit "  sub w1, w1, #1"
      emit "  str w1, [x0]"
      # Fall through to _stmt_${i}_end, the address we pushed.
      emit "  b _stmt_${i}_end"
    else
      emit "  b _rt_syslib_${syslib_num}"
    fi
  else
    emit "  b _stmt_${target_ref}"
  fi
}

codegen_next_from() {
  # Note [NextFromExtension]
  #   Non-standard primitive borrowed from CLC-INTERCAL, see
  #   docs/loop-extension.md. Plain backward branch with optional
  #   bit-0 conditional. Does NOT push the NEXT stack -- this is the
  #   feature that makes finite loops sound (no E123 on the 80th
  #   iteration). Cannot RESUME from it; the labelled target is reached
  #   directly.
  local i=$1
  local target_label="${stmt_next_target[$i]}"
  local target_ref="${label_to_stmt[$target_label]:-}"
  local expr_str="${stmt_next_from_expr[$i]}"

  if [[ -z "$target_ref" ]]; then
    die_compile "129" "PROGRAM HAS GOTTEN LOST (NEXT FROM to undefined label ($target_label))"
  fi

  if [[ -z "$expr_str" ]]; then
    emit "  b _stmt_${target_ref}"
  else
    parse_text="$expr_str"
    parse_pos=0
    parse_expr ""
    codegen_expr $parse_result
    emit "  tbnz w0, #0, _stmt_${target_ref}"
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

  # Note [E621Elim]: skip cbz when literal-nonzero RESUME proven safe.
  if ! ( (( ${+stmt_e621_safe[$i]} )) && opt_bisect_check "elim_e621_stmt_$i" ); then
    emit "  cbz w0, _rt_error_E621"
  fi
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
    if [[ -z "$target_stmt" || "$target_stmt" == syslib_* || "$target_stmt" == syscall_666 ]]; then
      die_compile "139" "ABSTAIN FROM nonexistent or reserved label ($target_label)"
    fi
    local abs_offset=$((target_stmt-1))
    emit "  adrp x0, _stmt_flags@PAGE"
    emit "  add x0, x0, _stmt_flags@PAGEOFF"
    emit "  mov w1, #1"
    if (( abs_offset > 4095 )); then
      emit "  mov w9, #${abs_offset}"
      emit "  strb w1, [x0, x9]"
    else
      emit "  strb w1, [x0, #${abs_offset}]"
    fi
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
    if [[ -z "$target_stmt" || "$target_stmt" == syslib_* || "$target_stmt" == syscall_666 ]]; then
      die_compile "139" "REINSTATE of nonexistent or reserved label ($target_label)"
    fi
    local rei_offset=$((target_stmt-1))
    emit "  adrp x0, _stmt_flags@PAGE"
    emit "  add x0, x0, _stmt_flags@PAGEOFF"
    emit "  mov w1, #0"
    if (( rei_offset > 4095 )); then
      emit "  mov w9, #${rei_offset}"
      emit "  strb w1, [x0, x9]"
    else
      emit "  strb w1, [x0, #${rei_offset}]"
    fi
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

  # Validate gerunds before emitting any code -- unknown gerunds are a
  # silent bug otherwise.
  for g in "${gerunds[@]}"; do
    if [[ -z "${gerund_map[$g]:-}" ]]; then
      die_compile "017" "DO YOU EXPECT ME TO FIGURE THIS OUT? (UNKNOWN GERUND: $g)"
    fi
  done

  emit "  adrp x0, _stmt_flags@PAGE"
  emit "  add x0, x0, _stmt_flags@PAGEOFF"
  emit "  mov w1, #${flag_value}"

  for g in "${gerunds[@]}"; do
    local types="${gerund_map[$g]:-}"
    [[ -z "$types" ]] && continue
    local j=""
    for (( j=1; j<=stmt_count; j++ )); do
      for t in ${=types}; do
        if [[ "${stmt_type[$j]}" == "$t" ]]; then
          local ger_offset=$((j-1))
          if (( ger_offset > 4095 )); then
            emit "  mov w9, #${ger_offset}"
            emit "  strb w1, [x0, x9]"
          else
            emit "  strb w1, [x0, #${ger_offset}]"
          fi
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
  # Push value (with bounds check - max 1024 entries per stash)
  emit "  adrp x2, _${prefix}_${num}_stash_sp@PAGE"
  emit "  add x2, x2, _${prefix}_${num}_stash_sp@PAGEOFF"
  emit "  ldr w3, [x2]"
  emit "  cmp w3, #1023"
  emit "  b.gt _rt_error_E000"
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
  # Note [E436Elim]: skip cbz when STASH on every path proven.
  if ! ( (( ${+stmt_e436_safe[$stmt_idx]} )) && opt_bisect_check "elim_e436_stmt_$stmt_idx" ); then
    emit "  cbz w3, _rt_error_E436"
  fi
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
# SECTION 8: Data section (program-specific only)
# ============================================================
# Runtime routines, error handlers, syslib, and their data/BSS
# are in external files: runtime.s and syslib_native.s

# Emit per-statement flag bytes (renamed _syslib_stmt_flags by post-
# process) and variables-used-by-syslib as common symbols (.comm) so
# that the user binary's regular BSS declarations merge with them at
# link time. Used by --emit-syslib mode.
emit_stmt_flags_only() {
  emit ""
  emit "// ========== Syslib Data =========="
  emit ".section __DATA,__data"
  emit "_stmt_flags:"
  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    if (( stmt_negated[$i] )); then
      emit "  .byte 1"
    else
      emit "  .byte 0"
    fi
  done
  emit ""

  # Variables: emit as common symbols so the linker merges with user
  # code's BSS declarations of the same names. Uninitialised; size
  # matches the regular `.space N` allocations from emit_data.
  local var=""
  for var in ${(k)used_spot}; do
    emit ".comm _spot_${var}, 4, 2"
    emit ".comm _spot_${var}_ign, 1, 0"
    emit ".comm _spot_${var}_stash_ptr, 8, 3"
    emit ".comm _spot_${var}_stash_sp, 4, 2"
  done
  for var in ${(k)used_twospot}; do
    emit ".comm _twospot_${var}, 4, 2"
    emit ".comm _twospot_${var}_ign, 1, 0"
    emit ".comm _twospot_${var}_stash_ptr, 8, 3"
    emit ".comm _twospot_${var}_stash_sp, 4, 2"
  done
  for var in ${(k)used_tail}; do
    emit ".comm _tail_${var}_ptr, 8, 3"
    emit ".comm _tail_${var}_ndim, 4, 2"
    emit ".comm _tail_${var}_dims, 32, 3"
    emit ".comm _tail_${var}_ign, 1, 0"
    emit ".comm _tail_${var}_stash_ptr, 8, 3"
    emit ".comm _tail_${var}_stash_sp, 4, 2"
  done
  for var in ${(k)used_hybrid}; do
    emit ".comm _hybrid_${var}_ptr, 8, 3"
    emit ".comm _hybrid_${var}_ndim, 4, 2"
    emit ".comm _hybrid_${var}_dims, 32, 3"
    emit ".comm _hybrid_${var}_ign, 1, 0"
    emit ".comm _hybrid_${var}_stash_ptr, 8, 3"
    emit ".comm _hybrid_${var}_stash_sp, 4, 2"
  done
}

emit_data() {
  emit ""
  emit "// ========== Program Data =========="
  # Statement flags (in __DATA,__data because negated stmts start at 1)
  emit ".section __DATA,__data"
  emit "_stmt_flags:"
  local i=""
  for (( i=1; i<=stmt_count; i++ )); do
    if (( stmt_negated[$i] )); then
      emit "  .byte 1"
    else
      emit "  .byte 0"
    fi
  done
  emit ""

  # Program variables BSS
  emit ".section __DATA,__bss"
  emit ""

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
}
# ============================================================
# SECTION 9: Main driver
# ============================================================

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/../.."
USE_PURE_SYSLIB=0

# Platform detection (override via INTERCAL_PLATFORM env var)
if [[ -n "${INTERCAL_PLATFORM:-}" ]]; then
  _INTERCAL_PLATFORM="$INTERCAL_PLATFORM"
else
  _INTERCAL_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  _INTERCAL_ARCH="$(uname -m)"
  case "${_INTERCAL_OS}_${_INTERCAL_ARCH}" in
    darwin_arm64)  _INTERCAL_PLATFORM="macos_arm64" ;;
    linux_x86_64)  _INTERCAL_PLATFORM="linux_x86_64" ;;
    linux_aarch64) _INTERCAL_PLATFORM="linux_arm64" ;;
    *)             _INTERCAL_PLATFORM="macos_arm64" ;;
  esac
fi

DIAGNOSE_MODE=0
# --emit-syslib: compile a standalone syslib to assembly with global
# _rt_syslib_NNNN aliases at each labeled statement and all internal
# _stmt_* labels prefixed with _syslib_. Used by tools/build_syslib.sh
# to produce src/syslib/syslib_compiled/{platform}.s, which the normal
# user build then concatenates instead of the hand-written native one.
EMIT_SYSLIB_MODE=0
# Inspection-only modes that print an IR view to stdout and exit. They
# do not emit assembly or invoke cc.
EMIT_CFG_MODE=0
EMIT_3ADDR_MODE=0
EMIT_TOKENS_MODE=0
EMIT_IR_FULL_MODE=0
EMIT_SSA_MODE=0
EMIT_SCCP_MODE=0
EMIT_SCCP_WZ_MODE=0
EMIT_REGALLOC_MODE=0
EMIT_EFFECTS_MODE=0
EMIT_IR_REAL_MODE=0
TIME_REPORT=0
# Note [OptBisect]
#   --opt-bisect-limit=N caps the number of optional transformations
#   that fire. Setting N=0 disables every optimisation; binary search
#   pinpoints the offender behind a miscompile. --opt-bisect-verbose
#   prints APPLY/SKIP per transformation, mirroring LLVM's
#   -mllvm -opt-bisect-limit. The counter is GLOBAL across passes so
#   transformation N is the same regardless of which pass owns it.
typeset -i OPT_BISECT_LIMIT=-1
typeset -i OPT_BISECT_COUNT=0
OPT_BISECT_VERBOSE=0
# Parse command-line flags
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --pure-syslib)        USE_PURE_SYSLIB=1; shift ;;
    --diagnose)           DIAGNOSE_MODE=1; shift ;;
    --emit-syslib)        EMIT_SYSLIB_MODE=1; INTERCAL_ASM_ONLY=1; shift ;;
    --emit-cfg)           EMIT_CFG_MODE=1; shift ;;
    --emit-3addr)         EMIT_3ADDR_MODE=1; shift ;;
    --emit-tokens)        EMIT_TOKENS_MODE=1; shift ;;
    --emit-ir-full)       EMIT_IR_FULL_MODE=1; shift ;;
    --emit-ssa)           EMIT_SSA_MODE=1; shift ;;
    --emit-sccp)          EMIT_SCCP_MODE=1; shift ;;
    --emit-sccp-wz)       EMIT_SCCP_WZ_MODE=1; shift ;;
    --emit-regalloc)      EMIT_REGALLOC_MODE=1; shift ;;
    --emit-effects)       EMIT_EFFECTS_MODE=1; shift ;;
    --emit-ir-real)       EMIT_IR_REAL_MODE=1; shift ;;
    --time-report)        TIME_REPORT=1; shift ;;
    --opt-bisect-limit=*) OPT_BISECT_LIMIT=${1#--opt-bisect-limit=}; shift ;;
    --opt-bisect-verbose) OPT_BISECT_VERBOSE=1; shift ;;
    *) shift ;;
  esac
done

opt_bisect_check() {
  local name=$1
  OPT_BISECT_COUNT=$((OPT_BISECT_COUNT + 1))
  if (( OPT_BISECT_LIMIT >= 0 && OPT_BISECT_COUNT > OPT_BISECT_LIMIT )); then
    (( OPT_BISECT_VERBOSE )) && print -u2 "BISECT: SKIP  #$OPT_BISECT_COUNT $name"
    return 1
  fi
  (( OPT_BISECT_VERBOSE )) && print -u2 "BISECT: APPLY #$OPT_BISECT_COUNT $name"
  return 0
}

# Per-phase timing accumulator. zsh's $EPOCHREALTIME provides
# microsecond precision since the epoch.
typeset -A phase_times
typeset -a phase_order

time_phase() {
  local name=$1; shift
  local start=$EPOCHREALTIME
  "$@"
  local rc=$?
  local elapsed=$(( EPOCHREALTIME - start ))
  if (( ! ${+phase_times[$name]} )); then
    phase_order+=("$name")
    phase_times[$name]=$elapsed
  else
    phase_times[$name]=$(( phase_times[$name] + elapsed ))
  fi
  return $rc
}

print_time_report() {
  (( ! TIME_REPORT )) && return 0
  print -u2 "=== Compile-time breakdown ==="
  local total=0
  for name in "${phase_order[@]}"; do
    local v="${phase_times[$name]}"
    total=$(( total + v ))
    printf "  %-14s %.3f s\n" "$name" "$v" >&2
  done
  printf "  %-14s %.3f s\n" "total_phases" "$total" >&2
}

# Source platform-specific codegen overrides
if [[ "$_INTERCAL_PLATFORM" == "linux_x86_64" ]]; then
  source "$SCRIPT_DIR/codegen_x86_64.sh"
fi

main() {
  # If --pure-syslib, prepend syslib.i to source
  if (( USE_PURE_SYSLIB )) && (( needs_syslib )); then
    # This is called after first read, so we re-read with syslib prepended
    :
  fi

  time_phase read_source read_source

  # Prepend syslib.i if --pure-syslib (after reading source but before tokenizing)
  if (( USE_PURE_SYSLIB )); then
    local syslib_source
    syslib_source=$(cat "$ROOT_DIR/src/syslib/syslib.i" 2>/dev/null || true)
    if [[ -n "$syslib_source" ]]; then
      syslib_source=${syslib_source//$'\n'/ }
      syslib_source=${syslib_source//$'\t'/ }
      syslib_source=${syslib_source//$'\r'/ }
      syslib_source=${(U)syslib_source}
      SOURCE="$SOURCE $syslib_source"
    fi
  fi

  time_phase tokenize tokenize
  time_phase politeness check_politeness
  time_phase labels check_labels
  time_phase come_from resolve_come_from
  time_phase syslib detect_syslib
  time_phase flag_checks compute_flag_checks
  time_phase ignore_checks compute_ignore_checks
  time_phase e275_safety compute_e275_safety
  time_phase var_constants compute_var_constants
  time_phase unref_labels check_unreferenced_labels

  if (( DIAGNOSE_MODE )); then
    diagnose
    exit 0
  fi

  if (( EMIT_CFG_MODE )); then
    emit_cfg
    exit 0
  fi

  if (( EMIT_3ADDR_MODE )); then
    emit_3addr
    exit 0
  fi

  if (( EMIT_TOKENS_MODE )); then
    emit_tokens
    exit 0
  fi

  if (( EMIT_IR_FULL_MODE )); then
    emit_ir_full
    exit 0
  fi

  if (( EMIT_SSA_MODE )); then
    emit_ssa
    exit 0
  fi

  if (( EMIT_SCCP_MODE )); then
    emit_sccp
    exit 0
  fi

  if (( EMIT_SCCP_WZ_MODE )); then
    emit_sccp_wz
    exit 0
  fi

  if (( EMIT_REGALLOC_MODE )); then
    emit_regalloc
    exit 0
  fi

  if (( EMIT_EFFECTS_MODE )); then
    emit_effects
    exit 0
  fi

  if (( EMIT_IR_REAL_MODE )); then
    emit_ir_real
    exit 0
  fi

  time_phase codegen codegen_program
  time_phase peephole peephole_optimize

  # If we are emitting a standalone syslib library, rewrite all internal
  # _stmt_* references to _syslib_stmt_* (so they don't collide with
  # user code's _stmt_*) and inject .global _rt_syslib_NNNN aliases for
  # every statement that has an INTERCAL label in the syslib range.
  if (( EMIT_SYSLIB_MODE )); then
    asm=$(print -r -- "$asm" | sed -E 's/_stmt_/_syslib_stmt_/g')
    # Build the alias header. label_to_stmt[NNNN] is the syslib's own
    # internal statement number for the labeled statement; rewritten to
    # _syslib_stmt_K above.
    local aliases=""
    local lbl=""
    for lbl in "${(@k)label_to_stmt}"; do
      [[ "$lbl" =~ ^[0-9]+$ ]] || continue
      (( lbl >= 1000 && lbl <= 1999 )) || continue
      local target="${label_to_stmt[$lbl]}"
      [[ "$target" =~ ^[0-9]+$ ]] || continue
      aliases+=".global _rt_syslib_${lbl}"$'\n'
      aliases+="_rt_syslib_${lbl} = _syslib_stmt_${target}"$'\n'
    done
    asm="${aliases}${asm}"
  fi

  # Assemble: concatenate runtime + syslib (if needed) + program assembly
  local rt_file="$ROOT_DIR/src/runtime/${_INTERCAL_PLATFORM}.s"
  if [[ ! -f "$rt_file" ]]; then
    rt_file="$ROOT_DIR/src/runtime/macos_arm64.s"
  fi
  local runtime_files=("$rt_file")
  if (( needs_syslib && ! USE_PURE_SYSLIB )); then
    local sn_file=""
    # INTERCAL_SYSLIB=cache: use a content-cached pre-compilation of
    # the pure-INTERCAL syslib.i. Same semantics as --pure-syslib but
    # without the 30s parse cost on every build.
    if [[ "${INTERCAL_SYSLIB:-native}" == cache ]]; then
      sn_file=$(ensure_syslib_cache)
    fi
    if [[ -z "$sn_file" || ! -f "$sn_file" ]]; then
      sn_file="$ROOT_DIR/src/syslib/native/${_INTERCAL_PLATFORM}.s"
      if [[ ! -f "$sn_file" ]]; then
        sn_file="$ROOT_DIR/src/syslib/native/macos_arm64.s"
      fi
    fi
    runtime_files+=("$sn_file")
  fi
  # Determine compiler command
  local CC="${INTERCAL_CC:-cc}"

  # For Linux arm64: convert macOS assembly syntax to Linux syntax
  local asm_combined
  asm_combined=$(cat "${runtime_files[@]}" <(print -r -- "$asm"))

  if [[ "$_INTERCAL_PLATFORM" == linux_arm64 ]]; then
    # Note [SedPlatformConversion]
    #   We generate macOS ARM64 assembly natively and rewrite it to
    #   Linux ARM64 GNU assembler syntax via sed. The two platforms
    #   share the AArch64 ISA but diverge in:
    #     - Section directives (__TEXT,__text vs .text)
    #     - Relocation syntax (@PAGE/@PAGEOFF vs bare/:lo12:)
    #     - Syscall instruction (svc #0x80 vs svc #0)
    #     - Syscall numbers (Mach-O numbers vs Linux numbers)
    #     - Symbol prefix (_main vs main)
    #   Order matters: @PAGEOFF must be rewritten BEFORE @PAGE because
    #   "@PAGE" is a prefix of "@PAGEOFF". A naive @PAGE-first sed would
    #   leave residual "OFF" tokens. This is documented as a "real bug
    #   we encountered during CI" (see memory/bugs_learned.md).
    #   Linux x86-64 takes a different path: it has its own dedicated
    #   codegen backend (src/bootstrap/codegen_x86_64.sh) because the
    #   syntax differences are too large for sed to handle reliably.
    asm_combined=$(print -r -- "$asm_combined" | sed \
      -e 's/\.section __TEXT,__text/.text/' \
      -e 's/\.section __DATA,__data/.data/' \
      -e 's/\.section __DATA,__bss/.bss/' \
      -e 's/\([_a-zA-Z][_a-zA-Z0-9]*\)@PAGEOFF/:lo12:\1/g' \
      -e 's/\([_a-zA-Z][_a-zA-Z0-9]*\)@PAGE/\1/g' \
      -e 's/svc #0x80/svc #0/g' \
      -e 's/mov x3, #0x1002/mov x3, #0x22/' \
      -e 's/mov w1, #0x601/mov w2, #0x241/' \
      -e 's/mov x16, #1$/mov x8, #93/' \
      -e 's/mov x16, #4$/mov x8, #64/' \
      -e 's/mov x16, #3$/mov x8, #63/' \
      -e 's/mov x16, #5$/mov x8, #56/' \
      -e 's/mov x16, #6$/mov x8, #57/' \
      -e 's/mov x16, #197$/mov x8, #222/' \
      -e 's/mov x16, #500$/mov x8, #278/' \
      -e 's/\.global _main/.global main/' \
      -e 's/^_main:/main:/')
  fi

  # If INTERCAL_ASM_ONLY is set, emit (platform-converted) program assembly only
  if [[ -n "${INTERCAL_ASM_ONLY:-}" ]]; then
    local asm_program="$asm"
    if [[ "$_INTERCAL_PLATFORM" == linux_arm64 ]]; then
      asm_program=$(print -r -- "$asm_program" | sed \
        -e 's/\.section __TEXT,__text/.text/' \
        -e 's/\.section __DATA,__data/.data/' \
        -e 's/\.section __DATA,__bss/.bss/' \
        -e 's/\([_a-zA-Z][_a-zA-Z0-9]*\)@PAGEOFF/:lo12:\1/g' \
        -e 's/\([_a-zA-Z][_a-zA-Z0-9]*\)@PAGE/\1/g' \
        -e 's/svc #0x80/svc #0/g' \
        -e 's/mov x3, #0x1002/mov x3, #0x22/' \
        -e 's/mov w1, #0x601/mov w2, #0x241/' \
        -e 's/mov x16, #1$/mov x8, #93/' \
        -e 's/mov x16, #4$/mov x8, #64/' \
        -e 's/mov x16, #3$/mov x8, #63/' \
        -e 's/mov x16, #5$/mov x8, #56/' \
        -e 's/mov x16, #6$/mov x8, #57/' \
        -e 's/mov x16, #197$/mov x8, #222/' \
        -e 's/mov x16, #500$/mov x8, #278/' \
        -e 's/\.global _main/.global main/' \
        -e 's/^_main:/main:/')
    fi
    print -r -- "$asm_program"
    return 0
  fi

  # Reproducible-build flags: strip build-IDs on Linux and the temp
  # object name that cc embeds in symbol tables when reading stdin.
  # macOS dyld currently requires LC_UUID, so a UUID survives there.
  local repro_flags=()
  case "$_INTERCAL_PLATFORM" in
    linux_arm64|linux_x86_64)
      repro_flags=(-Wl,--build-id=none -Wl,-s)
      ;;
    macos_arm64)
      # Suppress cc's auto ad-hoc codesign so we can re-sign
      # deterministically below (only effective when reproducibility
      # is requested).
      if [[ -n "${INTERCAL_REPRODUCIBLE:-}" ]]; then
        repro_flags=(-Wl,-no_adhoc_codesign)
      fi
      ;;
  esac

  print -r -- "$asm_combined" | $CC "${repro_flags[@]}" -x assembler - -o "$TMPBIN" 2>&2
  local cc_exit=$?
  if [[ $cc_exit -ne 0 ]]; then
    exit 1
  fi

  # Optional macOS reproducibility: opt-in via INTERCAL_REPRODUCIBLE=1.
  # Sequence: strip metadata that contains the random temp object name,
  # rewrite LC_UUID with a content-derived hash, re-sign ad-hoc with
  # deterministic flags. Apple's arm64 toolchain auto-signs every
  # binary; modifying any byte invalidates the signature.
  if [[ -n "${INTERCAL_REPRODUCIBLE:-}" && "$_INTERCAL_PLATFORM" == macos_arm64 ]] \
       && command -v python3 >/dev/null 2>&1 \
       && command -v codesign >/dev/null 2>&1 \
       && command -v strip >/dev/null 2>&1; then
    strip "$TMPBIN" 2>/dev/null || true
    python3 "$ROOT_DIR/tools/rewrite_uuid.py" "$TMPBIN" 2>&2 || true
    codesign -fs - --identifier intercal --digest-algorithm=sha256 "$TMPBIN" 2>/dev/null || true
  fi

  cat "$TMPBIN"
  print_time_report
}

main
