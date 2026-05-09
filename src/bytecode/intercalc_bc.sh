#!/bin/zsh
# INTERCAL-to-bytecode compiler.
#
# Stack-based ISA (variables addressed by slot, expressions on stack):
#   IPUSH n        push n
#   VPUSH .N       push spot[N]
#   VPUSH2 :N      push twospot[N]
#   POPV .N        pop into spot[N]
#   POPV2 :N       pop into twospot[N]
#   MINGLE         pop two, push mingled (16,16 -> 32)
#   SELECT         pop val, mask; push selected bits
#   UAND           pop, push unary AND of adjacent bits
#   UOR            pop, push unary OR of adjacent bits
#   UXOR           pop, push unary XOR of adjacent bits
#   READOUT        pop, print Roman numerals (16-bit value)
#   READOUT2       pop, print Roman numerals (32-bit value)
#   STASH .N       push spot[N] onto its own stash stack
#   RETRIEVE .N    pop spot[N] from its stash stack
#   IGNORE .N      mark spot[N] read-only
#   REMEMBER .N    unmark
#   EXIT           terminate

set -euo pipefail

src=$(cat)
src=${src//$'\n'/ }
src=${src//$'\t'/ }
src=${src//$'\r'/ }
src=${(U)src}

src=${src//DO /$'\n'DO }
src=${src//PLEASE /$'\n'PLEASE }

# Hoist a label-prefix "(N)" that the DO/PLEASE-split left at the
# end of a line so it sticks to the start of the next statement
# chunk. We only treat trailing "(N)" as a label prefix when the
# line content BEFORE the (N) does not look like a target-reference
# context (COME FROM, NEXT, ABSTAIN FROM, REINSTATE).
typeset -a tmp_lines
tmp_lines=("${(@f)src}")
typeset -a out_lines
local L=""
local i_l=0
local n_lines=${#tmp_lines[@]}
for (( i_l=1; i_l<=n_lines; i_l++ )); do
  L="${tmp_lines[$i_l]}"
  if [[ "$L" =~ '^(.*[^[:space:]])[[:space:]]+(\([0-9]+\))[[:space:]]*$' ]]; then
    local before="${match[1]}"
    local lblpfx="${match[2]}"
    # Heuristic: if 'before' ends with a target-reference keyword,
    # the (N) is a target reference, not a label prefix. Leave the
    # line intact.
    if [[ "$before" =~ '(COME FROM|NEXT|ABSTAIN FROM|REINSTATE)$' ]]; then
      out_lines+=("$L")
    else
      out_lines+=("$before")
      # Prepend lblpfx to the next line if there is one.
      if (( i_l < n_lines )); then
        tmp_lines[$((i_l+1))]="${lblpfx} ${tmp_lines[$((i_l+1))]}"
      else
        out_lines+=("$lblpfx")
      fi
    fi
  else
    out_lines+=("$L")
  fi
done
src=$(printf '%s\n' "${out_lines[@]}")

# Compile a single expression into stack ops.
# Recursive descent over our small expression grammar:
#   expr := atom | unary expr | spark|rabbitears (expr op expr) close
#   atom := #N | .N | :N
#   op := $ (mingle) | ~ (select)
#   unary := & V ?
compile_expr() {
  local s="$1"
  s="${s## }"; s="${s%% }"
  # Strip outer balanced spark or rabbit-ears
  while [[ "$s" =~ "^'(.*)'$" ]] || [[ "$s" =~ '^"(.*)"$' ]]; do
    s="${match[1]}"
    s="${s## }"; s="${s%% }"
  done
  # Atom
  if [[ "$s" =~ '^#([0-9]+)$' ]]; then
    echo "IPUSH ${match[1]}"
    return
  fi
  if [[ "$s" =~ '^\.([0-9]+)$' ]]; then
    echo "VPUSH .${match[1]}"
    return
  fi
  if [[ "$s" =~ '^:([0-9]+)$' ]]; then
    echo "VPUSH2 :${match[1]}"
    return
  fi
  # Unary operator at start: & V ?
  local first="${s:0:1}"
  if [[ "$first" == "&" || "$first" == "V" || "$first" == "?" ]]; then
    local sub="${s:1}"
    sub="${sub## }"
    compile_expr "$sub"
    case "$first" in
      "&") echo "UAND" ;;
      "V") echo "UOR" ;;
      "?") echo "UXOR" ;;
    esac
    return
  fi
  # Binary operator: walk for '$' or '~' at top level (not nested).
  local i depth=0 ch op_pos=-1 op_ch=""
  for (( i=0; i<${#s}; i++ )); do
    ch="${s:$i:1}"
    [[ "$ch" == "'" || "$ch" == '"' ]] && (( depth++ ))
    if [[ "$ch" == "\$" || "$ch" == "~" ]] && (( depth == 0 )); then
      op_pos=$i
      op_ch="$ch"
      break
    fi
    [[ "$ch" == "'" || "$ch" == '"' ]] && (( depth-- ))
  done
  if (( op_pos >= 0 )); then
    local left="${s:0:$op_pos}"
    local right="${s:$((op_pos+1))}"
    compile_expr "$left"
    compile_expr "$right"
    case "$op_ch" in
      "\$") echo "MINGLE" ;;
      "~")  echo "SELECT" ;;
    esac
    return
  fi
  echo "ERROR: cannot compile expression: $s" >&2
  exit 1
}

while IFS= read -r line; do
  line="${line## }"
  line="${line%% }"
  [[ -z "$line" ]] && continue
  body="$line"
  # Detect a (N) prefix and emit a LABEL marker before the statement's
  # body. The COME FROM lookup later in the VM uses this marker to
  # decide whether the just-executed statement triggers a redirect.
  if [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]*(.*)$' ]]; then
    echo "LABEL ${match[1]}"
    body="${match[2]}"
  fi
  # Strip leading DO/PLEASE keywords; both with and without a
  # trailing space (the preprocessor occasionally splits a line at
  # the bare keyword).
  body="${body#DO }"
  body="${body#PLEASE }"
  [[ "$body" == "DO" ]] && body=""
  [[ "$body" == "PLEASE" ]] && body=""
  body="${body## }"
  body="${body%% }"

  # The line might contain only a label or only a stray PLEASE/DO
  # keyword (the surrounding "split on DO/PLEASE" preprocessing
  # leaves these alone). Skip emitting any op for an empty body.
  [[ -z "$body" ]] && continue

  if [[ "$body" =~ '^GIVE UP[[:space:]]*$' ]]; then
    echo "EXIT"
    echo "ESTMT"
    continue
  fi

  # COME FROM (N) marks the destination for label N's outgoing
  # transfer.
  if [[ "$body" =~ '^COME[[:space:]]+FROM[[:space:]]+\(([0-9]+)\)[[:space:]]*$' ]]; then
    echo "COMEFROM ${match[1]}"
    echo "ESTMT"
    continue
  fi

  # NEXT (N): push return PC, jump to label N. RESUME N: pop N
  # entries from the call stack, resume at the last popped PC.
  if [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]+NEXT[[:space:]]*$' ]]; then
    echo "CALL ${match[1]}"
    echo "ESTMT"
    continue
  fi
  # NEXT FROM (N): unconditional or conditional backward branch with
  # no call-stack push. Mirror the native compiler's loop primitive.
  if [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]+NEXT[[:space:]]+FROM[[:space:]]+(.+)$' ]]; then
    compile_expr "${match[2]}"
    echo "BRANCH_NZ ${match[1]}"
    echo "ESTMT"
    continue
  fi
  if [[ "$body" =~ '^\(([0-9]+)\)[[:space:]]+NEXT[[:space:]]+FROM[[:space:]]*$' ]]; then
    echo "BRANCH ${match[1]}"
    echo "ESTMT"
    continue
  fi
  if [[ "$body" =~ '^RESUME[[:space:]]+#([0-9]+)[[:space:]]*$' ]]; then
    echo "RESUME ${match[1]}"
    echo "ESTMT"
    continue
  fi
  if [[ "$body" =~ '^FORGET[[:space:]]+#([0-9]+)[[:space:]]*$' ]]; then
    echo "FORGET ${match[1]}"
    echo "ESTMT"
    continue
  fi

  if [[ "$body" =~ '^WRITE IN[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "WRITEIN ${match[1]}"
    echo "ESTMT"
    continue
  fi

  if [[ "$body" =~ '^READ OUT[[:space:]]+\.([0-9]+)[[:space:]]*$' ]]; then
    echo "VPUSH .${match[1]}"
    echo "READOUT"
    echo "ESTMT"
    continue
  fi
  if [[ "$body" =~ '^READ OUT[[:space:]]+:([0-9]+)[[:space:]]*$' ]]; then
    echo "VPUSH2 :${match[1]}"
    echo "READOUT2"
    echo "ESTMT"
    continue
  fi

  # Assignment: .N <- expr or :N <- expr
  if [[ "$body" =~ '^(\.[0-9]+|:[0-9]+)[[:space:]]*<-[[:space:]]*(.+)$' ]]; then
    local lhs="${match[1]}"
    local rhs="${match[2]}"
    compile_expr "$rhs"
    if [[ "$lhs" == .* ]]; then
      echo "POPV ${lhs}"
    else
      echo "POPV2 ${lhs}"
    fi
    echo "ESTMT"
    continue
  fi

  if [[ "$body" =~ '^STASH[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "STASH ${match[1]}"
    echo "ESTMT"
    continue
  fi
  if [[ "$body" =~ '^RETRIEVE[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "RETRIEVE ${match[1]}"
    echo "ESTMT"
    continue
  fi
  if [[ "$body" =~ '^IGNORE[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "IGNORE ${match[1]}"
    echo "ESTMT"
    continue
  fi
  if [[ "$body" =~ '^REMEMBER[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "REMEMBER ${match[1]}"
    echo "ESTMT"
    continue
  fi

  echo "ERROR: unsupported in bytecode subset: $line" >&2
  exit 1
done <<< "$src"
