#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${PUSHWRITE_UNIT_TEST_OUTPUT_DIR:-}"
if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$(mktemp -d /tmp/pushwrite-unit-tests.XXXXXXXX)"
  trap 'rm -rf "$OUTPUT_DIR"' EXIT INT TERM
elif [[ -L "$OUTPUT_DIR" ]]; then
  echo "Refusing symlink unit-test output directory: $OUTPUT_DIR" >&2
  exit 64
fi
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TEST_BINARY="$OUTPUT_DIR/PushWriteCoreTests"

mkdir -p "$MODULE_CACHE_DIR"

xcrun swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos13.0 \
  "$ROOT_DIR/core/workflow/PushWriteCore.swift" \
  "$ROOT_DIR/tests/unit/PushWriteCoreTests.swift" \
  -o "$TEST_BINARY"

"$TEST_BINARY"
