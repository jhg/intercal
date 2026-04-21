#!/bin/sh
# setup_platform.sh - Create symlinks for current platform runtime/syslib

PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m)"

# Normalize platform name
case "$PLATFORM" in
    darwin_arm64)  PLATFORM="macos_arm64" ;;
    linux_x86_64)  PLATFORM="linux_x86_64" ;;
    linux_aarch64) PLATFORM="linux_arm64" ;;
    *)
        echo "Unsupported platform: $PLATFORM" >&2
        exit 1
        ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ln -sf "runtime_${PLATFORM}.s" "${SCRIPT_DIR}/runtime.s"
ln -sf "syslib_native_${PLATFORM}.s" "${SCRIPT_DIR}/syslib_native.s"
echo "Platform: $PLATFORM"
echo "Linked: runtime_${PLATFORM}.s -> runtime.s"
echo "Linked: syslib_native_${PLATFORM}.s -> syslib_native.s"
