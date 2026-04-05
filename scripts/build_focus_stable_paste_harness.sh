#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/app/macos/FocusStablePasteHarness/main.swift"
INFO_PLIST="$ROOT_DIR/app/macos/FocusStablePasteHarness/Info.plist"
OUTPUT_DIR="${1:-/tmp/pushwrite-focus-stable-paste-harness}"
APP_DIR="$OUTPUT_DIR/FocusStablePasteHarness.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
SDK_PATH="$(xcrun --show-sdk-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$MODULE_CACHE_DIR"
cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  -framework ApplicationServices \
  "$SOURCE_FILE" \
  -o "$MACOS_DIR/FocusStablePasteHarness"

codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true

printf '%s\n' "$APP_DIR"
