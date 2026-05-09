#!/bin/zsh
# Minimal INTERCAL-to-bytecode compiler. Reads INTERCAL on stdin,
# emits one bytecode instruction per line on stdout.
#
# Supported subset:
#   DO .N <- #M
#   PLEASE GIVE UP / DO GIVE UP
#   DO READ OUT .N
#
# Anything else: error.
set -euo pipefail

src=$(cat)
src=${src//$'\n'/ }
src=${src//$'\t'/ }
src=${src//$'\r'/ }
# Uppercase
src=${(U)src}

# Split on DO|PLEASE keywords. Heuristic: insert newline before each.
src=${src//DO /$'\n'DO }
src=${src//PLEASE /$'\n'PLEASE }

while IFS= read -r line; do
  # Strip leading/trailing whitespace
  line="${line## }"
  line="${line%% }"
  [[ -z "$line" ]] && continue
  # Remove leading verb
  body="$line"
  body="${body#DO }"
  body="${body#PLEASE }"
  body="${body## }"

  if [[ "$body" =~ '^GIVE UP[[:space:]]*$' ]]; then
    echo "EXIT"
    continue
  fi
  if [[ "$body" =~ '^READ OUT[[:space:]]+\.([0-9]+)[[:space:]]*$' ]]; then
    echo "READOUT ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^\.([0-9]+)[[:space:]]*<-[[:space:]]*#([0-9]+)[[:space:]]*$' ]]; then
    echo "LOADI ${match[1]} ${match[2]}"
    continue
  fi
  echo "ERROR: unsupported in bytecode subset: $line" >&2
  exit 1
done <<< "$src"
