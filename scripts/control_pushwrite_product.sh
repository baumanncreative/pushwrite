#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/scripts/control_pushwrite_product.swift"
OUTPUT_DIR="/tmp/pushwrite-product-tools"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TOOL_PATH="$OUTPUT_DIR/control_pushwrite_product"
SDK_PATH="$(xcrun --show-sdk-path)"

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE_DIR"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  "$SOURCE_FILE" \
  -o "$TOOL_PATH"

exec "$TOOL_PATH" "$@"
