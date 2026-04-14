#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WHISPER_SOURCE_DIR="${ROOT_DIR}/third_party/whisper.cpp"
BUILD_ROOT="${${1:-$ROOT_DIR/build/whispercpp}:A}"
BUILD_DIR="${BUILD_ROOT}/build"
LOCAL_CMAKE="${BUILD_ROOT}/pydeps/cmake/data/bin/cmake"

if [[ ! -d "$WHISPER_SOURCE_DIR" ]]; then
  echo "Missing whisper.cpp source at $WHISPER_SOURCE_DIR" >&2
  exit 1
fi

if [[ -x "$LOCAL_CMAKE" ]]; then
  CMAKE_BIN="$LOCAL_CMAKE"
elif command -v cmake >/dev/null 2>&1; then
  CMAKE_BIN="$(command -v cmake)"
else
  echo "Missing cmake. Provide it on PATH or at $LOCAL_CMAKE" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"

"$CMAKE_BIN" -S "$WHISPER_SOURCE_DIR" -B "$BUILD_DIR"
"$CMAKE_BIN" --build "$BUILD_DIR" --target whisper-cli -j 4

printf '%s\n' "$BUILD_DIR/bin/whisper-cli"
