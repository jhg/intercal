#!/bin/sh
# setup_platform.sh - Detect current platform and report
# No symlinks needed - intercalc.sh resolves paths directly via src/runtime/

PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m)"

case "$PLATFORM" in
    darwin_arm64)  PLATFORM="macos_arm64" ;;
    linux_x86_64)  PLATFORM="linux_x86_64" ;;
    linux_aarch64) PLATFORM="linux_arm64" ;;
    *)
        echo "WARNING: Unsupported platform: $PLATFORM, defaulting to macos_arm64" >&2
        PLATFORM="macos_arm64"
        ;;
esac

echo "Platform: $PLATFORM"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/src/runtime/${PLATFORM}.s" ]; then
    echo "Runtime: src/runtime/${PLATFORM}.s (found)"
else
    echo "Runtime: src/runtime/${PLATFORM}.s (NOT FOUND)" >&2
fi
if [ -f "$SCRIPT_DIR/src/syslib/native/${PLATFORM}.s" ]; then
    echo "Syslib:  src/syslib/native/${PLATFORM}.s (found)"
else
    echo "Syslib:  src/syslib/native/${PLATFORM}.s (NOT FOUND)" >&2
fi
