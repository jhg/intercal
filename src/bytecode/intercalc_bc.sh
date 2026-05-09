#!/bin/zsh
# INTERCAL-to-bytecode compiler. Reads INTERCAL on stdin, emits
# bytecode (one instruction per line) on stdout.
#
# Subset (extended):
#   DO .N <- #M               LOADI N M
#   DO .N <- .M               COPY N M
#   DO :N <- #M               LOADI2 N M (twospot)
#   DO :N <- :M               COPY2 N M
#   PLEASE GIVE UP            EXIT
#   DO READ OUT .N            READOUT N
#   DO READ OUT :N            READOUT2 N (twospot)
#   DO STASH .N               STASH N
#   DO RETRIEVE .N            RETRIEVE N
#   DO IGNORE .N              IGNORE N
#   DO REMEMBER .N            REMEMBER N
#
# Anything else: error. The intent is to demonstrate a non-trivial
# subset that includes scalar arithmetic operations through a small
# stack architecture.
set -euo pipefail

src=$(cat)
src=${src//$'\n'/ }
src=${src//$'\t'/ }
src=${src//$'\r'/ }
src=${(U)src}

# Tokenise statements by inserting newlines before DO|PLEASE.
src=${src//DO /$'\n'DO }
src=${src//PLEASE /$'\n'PLEASE }

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
    echo "READOUT ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^READ OUT[[:space:]]+:([0-9]+)[[:space:]]*$' ]]; then
    echo "READOUT2 ${match[1]}"
    continue
  fi

  if [[ "$body" =~ '^\.([0-9]+)[[:space:]]*<-[[:space:]]*#([0-9]+)[[:space:]]*$' ]]; then
    echo "LOADI ${match[1]} ${match[2]}"
    continue
  fi
  if [[ "$body" =~ '^\.([0-9]+)[[:space:]]*<-[[:space:]]*\.([0-9]+)[[:space:]]*$' ]]; then
    echo "COPY ${match[1]} ${match[2]}"
    continue
  fi
  if [[ "$body" =~ '^:([0-9]+)[[:space:]]*<-[[:space:]]*#([0-9]+)[[:space:]]*$' ]]; then
    echo "LOADI2 ${match[1]} ${match[2]}"
    continue
  fi
  if [[ "$body" =~ '^:([0-9]+)[[:space:]]*<-[[:space:]]*:([0-9]+)[[:space:]]*$' ]]; then
    echo "COPY2 ${match[1]} ${match[2]}"
    continue
  fi

  if [[ "$body" =~ '^STASH[[:space:]]+\.([0-9]+)[[:space:]]*$' ]]; then
    echo "STASH ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^RETRIEVE[[:space:]]+\.([0-9]+)[[:space:]]*$' ]]; then
    echo "RETRIEVE ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^IGNORE[[:space:]]+\.([0-9]+)[[:space:]]*$' ]]; then
    echo "IGNORE ${match[1]}"
    continue
  fi
  if [[ "$body" =~ '^REMEMBER[[:space:]]+\.([0-9]+)[[:space:]]*$' ]]; then
    echo "REMEMBER ${match[1]}"
    continue
  fi

  echo "ERROR: unsupported in bytecode subset: $line" >&2
  exit 1
done <<< "$src"
