#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WHISPER_SOURCE_DIR="${ROOT_DIR}/third_party/whisper.cpp"
BUILD_ROOT="${${1:-$ROOT_DIR/build/whispercpp}:A}"
BUILD_DIR="${BUILD_ROOT}/build"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"
DEPLOYMENT_TARGET="${PUSHWRITE_DEPLOYMENT_TARGET:-13.0}"

if [[ ! -d "$WHISPER_SOURCE_DIR" ]]; then
  echo "Missing whisper.cpp source at $WHISPER_SOURCE_DIR" >&2
  exit 1
fi

CMAKE_BIN="$("$ROOT_DIR/scripts/resolve_verified_cmake.sh")"

mkdir -p "$BUILD_DIR"

"$CMAKE_BIN" \
  -S "$WHISPER_SOURCE_DIR" \
  -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_SYSROOT="$SDK_PATH" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
  -DBUILD_SHARED_LIBS=OFF \
  -DGGML_BACKEND_DL=OFF \
  -DGGML_BLAS=OFF \
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DGGML_NATIVE=OFF \
  -DGGML_OPENMP=OFF \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_EXAMPLES=ON >&2
"$CMAKE_BIN" --build "$BUILD_DIR" --target whisper-cli -j 4 >&2

printf '%s\n' "$BUILD_DIR/bin/whisper-cli"
