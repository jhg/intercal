#!/bin/zsh
# bootstrap.sh - Recreate the entire toolchain from the primordial spark
# Requires: src/bootstrap/intercalc.sh + src/runtime/ + src/compiler/compiler.i
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

if [[ ! -f src/compiler/compiler.i ]]; then
  echo "ERROR: src/compiler/compiler.i not found."
  exit 1
fi

if ! grep -q "codegen\|_stmt_\|\.section" src/compiler/compiler.i 2>/dev/null; then
  echo "SKIP: compiler.i is not yet a complete compiler (Phase 2 in progress)"
  exit 0
fi

echo "=== INTERCAL Bootstrap ==="
echo ""

echo "Gen 1: bootstrap compiles compiler.i..."
zsh src/bootstrap/intercalc.sh < src/compiler/compiler.i > intercal_v1
chmod +x intercal_v1
echo "  intercal_v1 created ($(wc -c < intercal_v1 | tr -d ' ') bytes)"

echo ""
echo "Gen 2: self-compilation..."
./intercal_v1 src/compiler/compiler.i > /tmp/intercal_asm2.s
PLATFORM="$(_INTERCAL_PLATFORM:-macos_arm64)"
cat src/runtime/${PLATFORM}.s src/syslib/native/${PLATFORM}.s /tmp/intercal_asm2.s | cc -x assembler - -o intercal_v2
chmod +x intercal_v2

echo ""
echo "Gen 3: fixpoint..."
./intercal_v2 src/compiler/compiler.i > /tmp/intercal_asm3.s
if diff -q /tmp/intercal_asm2.s /tmp/intercal_asm3.s > /dev/null 2>&1; then
  echo "  FIXPOINT ACHIEVED"
else
  echo "  FIXPOINT FAILED"; exit 1
fi

cp intercal_v2 intercal_core
rm -f intercal_v1 intercal_v2 /tmp/intercal_asm2.s /tmp/intercal_asm3.s
echo ""
echo "Done: intercal_core ready"
zsh tests/run_tests.sh
