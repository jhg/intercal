#!/bin/zsh
# pipeline_dump.sh - introspect every stage of compiling an INTERCAL source.
#
# Usage:
#   tools/pipeline_dump.sh program.i
#   tools/pipeline_dump.sh program.i --platform linux_x86_64
#   tools/pipeline_dump.sh program.i --out /tmp/dump
#
# Writes the following to $OUT (default /tmp/intercal_dump):
#   01-source.i           Original INTERCAL source
#   02-normalized.i       Whitespace-normalized source
#   03-statements.txt     Statement list with DO/PLEASE/DON'T markers
#   04-politeness.txt     Politeness count + ratio
#   05-program.s          Program assembly emitted by the compiler
#   06-runtime.s          Platform runtime (copied)
#   07-syslib_native.s    Platform native syslib (copied)
#   08-combined.s         What cc actually assembles
#   09-cc-stderr.log      cc output
#   10-binary-info.txt    file + size of final binary
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR}/.."

SOURCE="${1:-}"
if [[ -z "$SOURCE" || ! -f "$SOURCE" ]]; then
  echo "Usage: $0 <program.i> [--platform P] [--out DIR]" >&2
  exit 2
fi
shift

PLAT=""
OUT="/tmp/intercal_dump"
while (( $# > 0 )); do
  case "$1" in
    --platform) PLAT="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$PLAT" ]]; then
  _OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  _ARCH="$(uname -m)"
  case "${_OS}_${_ARCH}" in
    darwin_arm64)  PLAT="macos_arm64" ;;
    linux_x86_64)  PLAT="linux_x86_64" ;;
    linux_aarch64) PLAT="linux_arm64" ;;
    *)             PLAT="macos_arm64" ;;
  esac
fi

rm -rf "$OUT"
mkdir -p "$OUT"

echo "pipeline_dump: $SOURCE -> $OUT (platform $PLAT)"

cp "$SOURCE" "$OUT/01-source.i"

# Normalize: collapse runs of whitespace, keep newlines
awk '{gsub(/[[:space:]]+/, " "); print}' "$SOURCE" > "$OUT/02-normalized.i"

# Statement extraction (heuristic: each line that mentions DO/PLEASE/DON'T).
{
  echo "# Each matching line is a statement candidate."
  echo "# P=PLEASE D=DO N=DON'T"
  grep -nE "^[[:space:]]*((PLEASE[[:space:]]+)?DO(N'T)?|PLEASE)[[:space:]]" "$SOURCE" || true
} > "$OUT/03-statements.txt"

# Politeness count.
total=$(grep -cE "^[[:space:]]*(PLEASE|DO|DON'T)" "$SOURCE" || true)
polite=$(grep -cE "^[[:space:]]*PLEASE" "$SOURCE" || true)
{
  echo "total statements (heuristic): $total"
  echo "PLEASE statements:            $polite"
  if (( total > 0 )); then
    pct=$(( polite * 100 / total ))
    echo "ratio:                        ${pct}%"
    if (( total < 5 )); then
      echo "VERDICT: under 5 statements - politeness not enforced"
    elif (( polite * 5 < total )); then
      echo "VERDICT: too rude (would emit ICL079I)"
    elif (( polite * 3 > total )); then
      echo "VERDICT: too polite (would emit ICL099I)"
    else
      echo "VERDICT: within [1/5, 1/3] bounds OK"
    fi
  fi
} > "$OUT/04-politeness.txt"

# Emit program assembly only (INTERCAL_ASM_ONLY mode of bootstrap).
INTERCAL_ASM_ONLY=1 INTERCAL_PLATFORM="$PLAT" \
  zsh "$ROOT_DIR/src/bootstrap/intercalc.sh" < "$SOURCE" > "$OUT/05-program.s" 2>"$OUT/09-cc-stderr.log" || \
  echo "NOTE: INTERCAL_ASM_ONLY failed; program assembly may be empty" >&2

cp "$ROOT_DIR/src/runtime/${PLAT}.s" "$OUT/06-runtime.s" 2>/dev/null || echo "no runtime for $PLAT" >&2
cp "$ROOT_DIR/src/syslib/native/${PLAT}.s" "$OUT/07-syslib_native.s" 2>/dev/null || echo "no syslib for $PLAT" >&2

cat "$OUT/06-runtime.s" "$OUT/07-syslib_native.s" "$OUT/05-program.s" > "$OUT/08-combined.s" 2>/dev/null || true

# Try a real build (only works if PLAT matches host)
BIN="$OUT/binary"
if cc -x assembler "$OUT/08-combined.s" -o "$BIN" 2>>"$OUT/09-cc-stderr.log"; then
  {
    file "$BIN" 2>/dev/null || echo "file tool not available"
    echo "size: $(wc -c < "$BIN") bytes"
  } > "$OUT/10-binary-info.txt"
else
  echo "cc failed; see 09-cc-stderr.log" > "$OUT/10-binary-info.txt"
fi

echo ""
echo "Dump written to $OUT:"
ls -la "$OUT"
echo ""
echo "Inspect with:"
echo "  head -30 $OUT/05-program.s"
echo "  cat $OUT/04-politeness.txt"
echo "  cat $OUT/09-cc-stderr.log"
