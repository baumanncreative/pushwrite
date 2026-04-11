#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/app/macos/PushWrite"
INFO_PLIST="$SOURCE_DIR/Info.plist"
STABLE_OUTPUT_DIR="${ROOT_DIR}/build/pushwrite-product"
DEFAULT_OUTPUT_DIR="${ROOT_DIR}/build/pushwrite-product-candidate"
OUTPUT_DIR="${${1:-$DEFAULT_OUTPUT_DIR}:A}"
APP_DIR="$OUTPUT_DIR/PushWrite.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
SDK_PATH="$(xcrun --show-sdk-path)"

if [[ "$OUTPUT_DIR" == "${STABLE_OUTPUT_DIR:A}" ]]; then
  echo "Refusing to build directly into stable product dir $STABLE_OUTPUT_DIR." >&2
  echo "Build a candidate bundle first, then promote it explicitly." >&2
  exit 64
fi

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
"$ROOT_DIR/scripts/inspect_pushwrite_product_identity.sh" "$APP_DIR" "$OUTPUT_DIR/build-identity.txt" >/dev/null

printf '%s\n' "$APP_DIR"
