#!/bin/zsh
# cross_test.sh - reproduce a Linux CI job locally via Docker.
#
# Usage:
#   tests/cross_test.sh linux_arm64
#   tests/cross_test.sh linux_x86_64
#   tests/cross_test.sh linux_x86_64 --image debian:12-slim
#
# Spawns a container on the requested Linux architecture (via qemu
# emulation on non-matching hosts), installs gcc + zsh, and runs
# the same suites as CI: verify_manifest, run_tests, test_syslib_pure,
# run_self_tests, run_stage3_tests.
#
# Leaves the container detached on failure if --keep is passed so you
# can docker exec into it to debug.
set -euo pipefail

ROOT_DIR="${0:A:h}/.."
PLAT="${1:-}"
shift || true

case "$PLAT" in
  linux_arm64)   DOCKER_PLAT="linux/arm64";  APK_SUFFIX="" ;;
  linux_x86_64)  DOCKER_PLAT="linux/amd64";  APK_SUFFIX="" ;;
  *)
    echo "Usage: $0 <linux_arm64|linux_x86_64> [--image <image>] [--keep]" >&2
    exit 2 ;;
esac

IMAGE="alpine:3.19"
KEEP=0
while (( $# > 0 )); do
  case "$1" in
    --image) IMAGE="$2"; shift ;;
    --keep)  KEEP=1 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

# Detect package manager at container runtime (works for any image)
INSTALL='
if command -v apk >/dev/null 2>&1; then
  apk add --no-cache gcc musl-dev zsh >/dev/null 2>&1
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq zsh gcc >/dev/null 2>&1
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y zsh gcc >/dev/null 2>&1
elif command -v yum >/dev/null 2>&1; then
  yum install -y zsh gcc >/dev/null 2>&1
else
  echo "no known package manager in container" >&2; exit 1
fi
'

echo "=== cross_test: $PLAT via $DOCKER_PLAT in $IMAGE ==="
echo

DOCKER_ARGS=(run --rm --platform "$DOCKER_PLAT" -v "$ROOT_DIR":/w -w /w "$IMAGE" sh -c)
(( KEEP )) && DOCKER_ARGS=(run -d --platform "$DOCKER_PLAT" -v "$ROOT_DIR":/w -w /w "$IMAGE" sh -c)

docker "${DOCKER_ARGS[@]}" "
set -e
$INSTALL >/dev/null 2>&1 || { echo 'dep install failed'; exit 1; }
echo '--- platform ---'
uname -sm
sh setup_platform.sh
echo '--- verify_manifest ---'
zsh tools/verify_manifest.sh
echo '--- bootstrap tests ---'
zsh tests/run_tests.sh
echo '--- pure syslib ---'
zsh tests/test_syslib_pure.sh
echo '--- build intercal_core ---'
rm -f intercal_core
zsh src/bootstrap/intercalc.sh < src/compiler/compiler.i > intercal_core 2>/dev/null
chmod +x intercal_core
echo '--- self-hosted tests ---'
zsh tests/run_self_tests.sh
echo '--- stage3 tests ---'
rm -f stage3_bin
zsh tests/run_stage3_tests.sh
"
