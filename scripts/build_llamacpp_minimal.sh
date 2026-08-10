#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LLAMA_SOURCE_DIR="$ROOT_DIR/third_party/llama.cpp"
BUILD_ROOT="${${1:-$ROOT_DIR/build/llamacpp}:A}"
BUILD_DIR="$BUILD_ROOT/build"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"
DEPLOYMENT_TARGET="${PUSHWRITE_DEPLOYMENT_TARGET:-13.0}"

if [[ ! -d "$LLAMA_SOURCE_DIR" ]]; then
  echo "Missing llama.cpp source at $LLAMA_SOURCE_DIR" >&2
  exit 1
fi

CMAKE_BIN="$("$ROOT_DIR/scripts/resolve_verified_cmake.sh")"

mkdir -p "$BUILD_DIR"

"$CMAKE_BIN" \
  -S "$LLAMA_SOURCE_DIR" \
  -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_SYSROOT="$SDK_PATH" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
  -DBUILD_SHARED_LIBS=OFF \
  -DGGML_BACKEND_DL=OFF \
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DGGML_BLAS=OFF \
  -DGGML_NATIVE=OFF \
  -DGGML_OPENMP=OFF \
  -DGGML_RPC=OFF \
  -DLLAMA_OPENSSL=OFF \
  -DLLAMA_SUBPROCESS=OFF \
  -DLLAMA_BUILD_UI=OFF \
  -DLLAMA_BUILD_NUMBER=10227 \
  -DLLAMA_BUILD_COMMIT=f5919bf458ef190468b5c329bb293f8a54a1e69c \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_TOOLS=ON >&2
"$CMAKE_BIN" --build "$BUILD_DIR" --target llama-completion -j 4 >&2

printf '%s\n' "$BUILD_DIR/bin/llama-completion"
