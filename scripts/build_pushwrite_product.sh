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
WHISPER_RESOURCES_DIR="$RESOURCES_DIR/whisper"
WHISPER_BIN_DIR="$WHISPER_RESOURCES_DIR/bin"
WHISPER_MODELS_DIR="$WHISPER_RESOURCES_DIR/models"
WHISPER_CLI_SOURCE="$ROOT_DIR/build/whispercpp/build/bin/whisper-cli"
WHISPER_MODEL_SOURCE="$ROOT_DIR/models/ggml-tiny.bin"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
SDK_PATH="$(xcrun --show-sdk-path)"

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

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$WHISPER_BIN_DIR" "$WHISPER_MODELS_DIR" "$MODULE_CACHE_DIR"
cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  -framework ApplicationServices \
  -framework AVFoundation \
  -framework Carbon \
  "$SOURCE_DIR/main.swift" \
  -o "$MACOS_DIR/PushWrite"

cp "$WHISPER_CLI_SOURCE" "$WHISPER_BIN_DIR/whisper-cli"
chmod +x "$WHISPER_BIN_DIR/whisper-cli"
cp "$WHISPER_MODEL_SOURCE" "$WHISPER_MODELS_DIR/ggml-tiny.bin"

codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
"$ROOT_DIR/scripts/inspect_pushwrite_product_identity.sh" "$APP_DIR" "$OUTPUT_DIR/build-identity.txt" >/dev/null

printf '%s\n' "$APP_DIR"
