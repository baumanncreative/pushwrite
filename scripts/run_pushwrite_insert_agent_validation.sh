#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/scripts/run_pushwrite_insert_agent_validation.swift"
OUTPUT_DIR="/tmp/pushwrite-insert-agent-tools"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TOOL_PATH="$OUTPUT_DIR/run_pushwrite_insert_agent_validation"
SDK_PATH="$(xcrun --show-sdk-path)"

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE_DIR"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  "$SOURCE_FILE" \
  -o "$TOOL_PATH"

exec "$TOOL_PATH" "$@"
