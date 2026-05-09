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
  body="${body#DO }"
  body="${body#PLEASE }"
  body="${body## }"

  if [[ "$body" =~ '^GIVE UP[[:space:]]*$' ]]; then
    echo "EXIT"
    continue
  fi

  if [[ "$body" =~ '^READ OUT[[:space:]]+\.([0-9]+)[[:space:]]*$' ]]; then
    echo "VPUSH .${match[1]}"
    echo "READOUT"
    continue
  fi
  if [[ "$body" =~ '^READ OUT[[:space:]]+:([0-9]+)[[:space:]]*$' ]]; then
    echo "VPUSH2 :${match[1]}"
    echo "READOUT2"
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
    continue
  fi

  if [[ "$body" =~ '^STASH[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "STASH ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^RETRIEVE[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "RETRIEVE ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^IGNORE[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "IGNORE ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^REMEMBER[[:space:]]+(\.[0-9]+|:[0-9]+)[[:space:]]*$' ]]; then
    echo "REMEMBER ${match[1]}"
    continue
  fi

  echo "ERROR: unsupported in bytecode subset: $line" >&2
  exit 1
done <<< "$src"
