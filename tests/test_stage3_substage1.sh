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
  local name="$1" src="$2" exp_len="$3" exp_d="$4" exp_p="$5" exp_do="$6" exp_pl="$7"
  local in=$(mktemp /tmp/sub1_in.XXXXXX)
  printf '%s' "$src" > "$in"
  local out
  out=$("$SUB1_BIN" "$in")
  local -a lines
  lines=("${(@f)out}")
  local actual_len="${lines[1]:-}"
  local actual_d="${lines[2]:-}"
  local actual_p="${lines[3]:-}"
  local actual_do="${lines[4]:-}"
  local actual_pl="${lines[5]:-}"
  if [[ "$actual_len" == "$exp_len" ]] && [[ "$actual_d" == "$exp_d" ]] \
     && [[ "$actual_p" == "$exp_p" ]] && [[ "$actual_do" == "$exp_do" ]] \
     && [[ "$actual_pl" == "$exp_pl" ]]; then
    echo "PASS $name (len=$actual_len d=$actual_d p=$actual_p do=$actual_do pl=$actual_pl)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name: expected len=$exp_len d=$exp_d p=$exp_p do=$exp_do pl=$exp_pl"
    echo "       got len=$actual_len d=$actual_d p=$actual_p do=$actual_do pl=$actual_pl"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$in"
}

# Counts include the 'P' in "UP" (every program ends with GIVE UP).
# DO-count tracks two-byte 'DO' sequences (statement-start proxy).
# PL-count tracks two-byte 'PL' sequences (PLEASE-start proxy).

# 'DO GIVE UP' = 11 bytes; 1 D; 1 P (UP); 1 DO; 0 PL.
run_case "give_up" $'DO GIVE UP\n' "XI" "I" "I" "I" ""

# 'DO READ OUT #5' + 'DO GIVE UP' = 26 bytes; 3 Ds; 1 P; 2 DOs; 0 PLs.
run_case "read_out_5" $'DO READ OUT #5\nDO GIVE UP\n' "XXVI" "III" "I" "II" ""

# 'DO .1 <- #5' + 'DO READ OUT .1' + 'DO GIVE UP' = 38 bytes;
# 4 Ds; 1 P; 3 DOs; 0 PLs.
run_case "assign_read" $'DO .1 <- #5\nDO READ OUT .1\nDO GIVE UP\n' "XXXVIII" "IV" "I" "III" ""

# 'PLEASE DO GIVE UP' = 18 bytes; 1 D; 2 Ps; 1 DO; 1 PL.
run_case "with_please" $'PLEASE DO GIVE UP\n' "XVIII" "I" "II" "I" "I"

# 'DO READ OUT #5' + 'PLEASE DO GIVE UP' = 33 bytes; 3 Ds; 2 Ps;
# 2 DOs; 1 PL.
run_case "mixed" $'DO READ OUT #5\nPLEASE DO GIVE UP\n' "XXXIII" "III" "II" "II" "I"

rm -f "$SUB1_BIN"
echo ""
echo "Total: $PASS passed, $FAIL failed"
exit $((FAIL > 0))
