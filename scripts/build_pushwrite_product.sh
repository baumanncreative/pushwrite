#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/app/macos/PushWrite"
INFO_PLIST="$SOURCE_DIR/Info.plist"
OUTPUT_DIR="${1:-$ROOT_DIR/build/pushwrite-product}"
APP_DIR="$OUTPUT_DIR/PushWrite.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
SDK_PATH="$(xcrun --show-sdk-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$MODULE_CACHE_DIR"
cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  -framework ApplicationServices \
  -framework Carbon \
  "$SOURCE_DIR/main.swift" \
  -o "$MACOS_DIR/PushWrite"

codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true

printf '%s\n' "$APP_DIR"
