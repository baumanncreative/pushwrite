#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="/tmp/pushwrite-ui-tests"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TEST_BINARY="$OUTPUT_DIR/PushWriteProductUITests"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE_DIR"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos13.0 \
  -framework AppKit \
  "$ROOT_DIR/app/macos/PushWrite/ProductUI.swift" \
  "$ROOT_DIR/tests/product_ui/PushWriteProductUITests.swift" \
  -o "$TEST_BINARY"

"$TEST_BINARY"
