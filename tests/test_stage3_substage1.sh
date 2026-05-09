#!/bin/zsh
# Verify stage3 substage 1 reads source bytes and counts a known
# pattern via a NEXT FROM-driven loop. Two outputs per run:
# Roman of total length, then Roman of 'D'-byte count.
setopt NO_ERR_EXIT

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."
COMPILER="${ROOT_DIR}/src/bootstrap/intercalc.sh"
SUB1="${ROOT_DIR}/src/compiler/stage3_substage1.i"
PASS=0
FAIL=0

# Build the substage 1 binary once.
SUB1_BIN=$(mktemp /tmp/sub1_bin.XXXXXX)
zsh "$COMPILER" < "$SUB1" > "$SUB1_BIN" 2>/dev/null
chmod +x "$SUB1_BIN"

run_case() {
  local name="$1" src="$2" exp_len="$3" exp_d="$4"
  local in=$(mktemp /tmp/sub1_in.XXXXXX)
  printf '%s' "$src" > "$in"
  local out
  out=$("$SUB1_BIN" "$in")
  local actual_len="${out%%$'\n'*}"
  local actual_d="${out##*$'\n'}"
  if [[ "$actual_len" == "$exp_len" ]] && [[ "$actual_d" == "$exp_d" ]]; then
    echo "PASS $name (len=$actual_len d=$actual_d)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name: expected len=$exp_len d=$exp_d, got len=$actual_len d=$actual_d"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$in"
}

# 'DO GIVE UP' with newline = 11 bytes; 1 'D'.
run_case "give_up" $'DO GIVE UP\n' "XI" "I"

# 'DO READ OUT #5' newline 'DO GIVE UP' newline = 26 bytes; 3 'D's.
run_case "read_out_5" $'DO READ OUT #5\nDO GIVE UP\n' "XXVI" "III"

# 'DO .1 <- #5' newline 'DO READ OUT .1' newline 'DO GIVE UP' newline = 38 bytes; 4 'D's.
run_case "assign_read" $'DO .1 <- #5\nDO READ OUT .1\nDO GIVE UP\n' "XXXVIII" "IV"

rm -f "$SUB1_BIN"
echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
