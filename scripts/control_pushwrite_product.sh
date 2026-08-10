#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/scripts/control_pushwrite_product.swift"
OUTPUT_DIR="$(mktemp -d /tmp/pushwrite-product-control.XXXXXXXX)"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TOOL_PATH="$OUTPUT_DIR/control_pushwrite_product"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"
trap 'rm -rf "$OUTPUT_DIR"' EXIT INT TERM

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE_DIR"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos13.0 \
  -framework AppKit \
  "$SOURCE_FILE" \
  -o "$TOOL_PATH"

"$TOOL_PATH" "$@"
