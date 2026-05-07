#!/bin/zsh
# build_syslib.sh - pre-compile src/syslib/syslib.i for the current
# platform and warm the cache. Useful in CI / release pipelines so
# users compiling with INTERCAL_SYSLIB=cache don't pay the 30-100s
# first-build penalty on their machine.
#
# The cache lives at $XDG_CACHE_HOME/intercal/syslib-<plat>-<hash>.s
# (defaults to $HOME/.cache/intercal/). It is keyed by sha256 of
# syslib.i so it auto-invalidates when the syslib changes.
set -euo pipefail

ROOT_DIR="${0:A:h}/.."
cd "$ROOT_DIR"

# Detect platform the same way intercalc.sh does so the cache key matches.
_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
_ARCH="$(uname -m)"
case "${_OS}_${_ARCH}" in
  darwin_arm64)  PLAT="macos_arm64" ;;
  linux_x86_64)  PLAT="linux_x86_64" ;;
  linux_aarch64) PLAT="linux_arm64" ;;
  *)             PLAT="${INTERCAL_PLATFORM:-macos_arm64}" ;;
esac

CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/intercal"
mkdir -p "$CACHE_ROOT"

if command -v shasum >/dev/null 2>&1; then
  H=$(shasum -a 256 src/syslib/syslib.i | awk '{print $1}')
elif command -v sha256sum >/dev/null 2>&1; then
  H=$(sha256sum src/syslib/syslib.i | awk '{print $1}')
else
  echo "no sha256 tool available" >&2
  exit 1
fi

CACHE="${CACHE_ROOT}/syslib-${PLAT}-${H:0:16}.s"

if [[ -f "$CACHE" ]]; then
  echo "syslib cache already present: $CACHE"
  exit 0
fi

echo "Building syslib cache for $PLAT (this takes 30-100s)..."
zsh src/bootstrap/intercalc.sh --emit-syslib < src/syslib/syslib.i > "$CACHE"
echo "Wrote $(wc -c < "$CACHE") bytes to $CACHE"
