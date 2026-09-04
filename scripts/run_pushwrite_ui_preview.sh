#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/pushwrite-ui-preview.XXXXXXXX)"
cleanup() {
  case "$BUILD_DIR" in
    /tmp/pushwrite-ui-preview.*) rm -rf "$BUILD_DIR" ;;
  esac
}
trap cleanup EXIT INT TERM

swiftc \
  -module-cache-path "$BUILD_DIR/module-cache" \
  -sdk "$(xcrun --show-sdk-path)" \
  -target arm64-apple-macos13.0 \
  -framework AppKit \
  "$ROOT_DIR/app/macos/PushWrite/ProductUI.swift" \
  "$ROOT_DIR/tests/product_ui/PushWriteProductUIPreview.swift" \
  -o "$BUILD_DIR/PushWriteProductUIPreview"

"$BUILD_DIR/PushWriteProductUIPreview"
