#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/scripts/run_pushwrite_transcription_insert_validation.swift"
OUTPUT_DIR="$(mktemp -d /tmp/pushwrite-transcription-validation.XXXXXXXX)"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TOOL_PATH="$OUTPUT_DIR/run_pushwrite_transcription_insert_validation"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"
export PUSHWRITE_INCLUDE_SENSITIVE_TEST_ARTIFACTS=1
trap 'rm -rf "$OUTPUT_DIR"' EXIT INT TERM

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE_DIR"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos13.0 \
  -framework AppKit \
  -framework ApplicationServices \
  "$SOURCE_FILE" \
  -o "$TOOL_PATH"

"$TOOL_PATH" "$@"
