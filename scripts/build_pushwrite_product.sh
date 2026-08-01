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
RESOURCES_DIR="$APP_DIR/Contents/Resources"
ASSETS_DIR="$SOURCE_DIR/Assets"
APP_ICON="$ASSETS_DIR/PushWrite.icns"
WHISPER_RESOURCES_DIR="$RESOURCES_DIR/whisper"
WHISPER_BIN_DIR="$WHISPER_RESOURCES_DIR/bin"
WHISPER_MODELS_DIR="$WHISPER_RESOURCES_DIR/models"
WHISPER_CLI_SOURCE="$ROOT_DIR/build/whispercpp/build/bin/whisper-cli"
WHISPER_MODEL_SOURCE="$ROOT_DIR/models/ggml-tiny.bin"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
ICON_BUILDER="$OUTPUT_DIR/build_pushwrite_icon"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"
SWIFT_TARGET="${PUSHWRITE_SWIFT_TARGET:-arm64-apple-macos13.0}"

if [[ "$OUTPUT_DIR" == "${STABLE_OUTPUT_DIR:A}" ]]; then
  echo "Refusing to build directly into stable product dir $STABLE_OUTPUT_DIR." >&2
  echo "Build a candidate bundle first, then promote it explicitly." >&2
  exit 64
fi

if [[ ! -f "$WHISPER_CLI_SOURCE" ]]; then
  echo "Missing whisper-cli source at $WHISPER_CLI_SOURCE" >&2
  echo "Build it first with scripts/build_whispercpp_minimal.sh." >&2
  exit 1
fi
if [[ ! -x "$WHISPER_CLI_SOURCE" ]]; then
  echo "whisper-cli source is not executable: $WHISPER_CLI_SOURCE" >&2
  exit 1
fi
if [[ ! -f "$WHISPER_MODEL_SOURCE" ]]; then
  echo "Missing whisper model source at $WHISPER_MODEL_SOURCE" >&2
  exit 1
fi
if [[ ! -f "$APP_ICON" ]]; then
  swiftc \
    -module-cache-path "$MODULE_CACHE_DIR/icon" \
    -sdk "$SDK_PATH" \
    -target "$SWIFT_TARGET" \
    "$ROOT_DIR/scripts/build_pushwrite_icon.swift" \
    -o "$ICON_BUILDER"
  "$ICON_BUILDER" "$ASSETS_DIR/PushWrite.iconset" "$APP_ICON"
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$WHISPER_BIN_DIR" "$WHISPER_MODELS_DIR" "$MODULE_CACHE_DIR"
cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -target "$SWIFT_TARGET" \
  -O \
  -framework AppKit \
  -framework ApplicationServices \
  -framework AVFoundation \
  -framework Carbon \
  -framework CryptoKit \
  "$ROOT_DIR/core/workflow/PushWriteCore.swift" \
  "$SOURCE_DIR/ProductUI.swift" \
  "$SOURCE_DIR/main.swift" \
  -o "$MACOS_DIR/PushWrite"

cp "$WHISPER_CLI_SOURCE" "$WHISPER_BIN_DIR/whisper-cli"
chmod +x "$WHISPER_BIN_DIR/whisper-cli"
cp "$WHISPER_MODEL_SOURCE" "$WHISPER_MODELS_DIR/ggml-tiny.bin"
cp "$ASSETS_DIR/PushWriteMenuBarTemplate.svg" "$RESOURCES_DIR/PushWriteMenuBarTemplate.svg"
cp "$ASSETS_DIR/model-manifest.json" "$WHISPER_RESOURCES_DIR/model-manifest.json"
cp "$APP_ICON" "$RESOURCES_DIR/PushWrite.icns"

find "$APP_DIR/Contents/Resources/whisper/bin" -type f -perm -111 -exec codesign --force --options runtime --sign - {} \;
codesign --force --options runtime --sign - "$APP_DIR"
"$ROOT_DIR/scripts/inspect_pushwrite_product_identity.sh" "$APP_DIR" "$OUTPUT_DIR/build-identity.txt" >/dev/null

printf '%s\n' "$APP_DIR"
