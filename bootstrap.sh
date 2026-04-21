#!/bin/zsh
# bootstrap.sh - Recreate the entire toolchain from the primordial spark
# Requires: intercalc.sh + runtime.s + syslib_native.s + compiler.i
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

if [[ ! -f compiler.i ]]; then
  echo "ERROR: compiler.i not found. The self-hosted compiler source is required."
  exit 1
fi

# Check if compiler.i is a complete compiler (Stage 8+)
# A complete compiler generates assembly output, not just echoes input
if ! grep -q "codegen\|_stmt_\|\.section" compiler.i 2>/dev/null; then
  echo "SKIP: compiler.i is not yet a complete compiler (Phase 2 in progress)"
  echo "Bootstrap requires a compiler that can generate assembly output."
  exit 0
fi

echo "=== INTERCAL Bootstrap ==="
echo ""

echo "Generation 1: Bootstrap compiler (intercalc.sh) compiles compiler.i..."
zsh intercalc.sh < compiler.i > intercal_v1
chmod +x intercal_v1
echo "  intercal_v1 created ($(wc -c < intercal_v1 | tr -d ' ') bytes)"

echo ""
echo "Generation 2: Self-compilation..."
./intercal_v1 compiler.i > /tmp/intercal_asm2.s
cat runtime.s syslib_native.s /tmp/intercal_asm2.s | cc -x assembler - -o intercal_v2
chmod +x intercal_v2
echo "  intercal_v2 created"

echo ""
echo "Generation 3: Fixpoint verification..."
./intercal_v2 compiler.i > /tmp/intercal_asm3.s

if diff -q /tmp/intercal_asm2.s /tmp/intercal_asm3.s > /dev/null 2>&1; then
  echo "  FIXPOINT ACHIEVED: generations 2 and 3 produce identical assembly"
else
  echo "  FIXPOINT FAILED: assembly output differs between generations 2 and 3"
  echo "  This indicates a compiler bug."
  diff /tmp/intercal_asm2.s /tmp/intercal_asm3.s | head -20
  exit 1
fi

echo ""
cp intercal_v2 intercal_core
rm -f intercal_v1 intercal_v2 /tmp/intercal_asm2.s /tmp/intercal_asm3.s
echo "=== Bootstrap complete ==="
echo "  intercal_core: the self-compiled INTERCAL compiler"
echo "  Use: ./intercal source.i -o output"
echo ""

echo "Running test suite..."
zsh tests/run_tests.sh
