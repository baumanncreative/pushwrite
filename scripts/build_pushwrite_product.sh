#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/app/macos/PushWrite"
INFO_PLIST="$SOURCE_DIR/Info.plist"
ENTITLEMENTS_PLIST="$SOURCE_DIR/PushWrite.entitlements"
STABLE_OUTPUT_DIR="${ROOT_DIR}/build/pushwrite-product"
DEFAULT_OUTPUT_DIR="${ROOT_DIR}/build/pushwrite-product-candidate"
OUTPUT_DIR_RAW="$DEFAULT_OUTPUT_DIR"
QA_BUILD=0
WHISPER_CLI_SOURCE_OVERRIDE=""
LOCAL_TEXT_CLI_SOURCE_OVERRIDE=""
CODESIGN_IDENTITY="-"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --qa)
      QA_BUILD=1
      shift
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for --output-dir." >&2; exit 64; }
      OUTPUT_DIR_RAW="$2"
      shift 2
      ;;
    --whisper-cli-source)
      [[ $# -ge 2 ]] || { echo "Missing value for --whisper-cli-source." >&2; exit 64; }
      WHISPER_CLI_SOURCE_OVERRIDE="$2"
      shift 2
      ;;
    --local-text-cli-source)
      [[ $# -ge 2 ]] || { echo "Missing value for --local-text-cli-source." >&2; exit 64; }
      LOCAL_TEXT_CLI_SOURCE_OVERRIDE="$2"
      shift 2
      ;;
    --codesign-identity)
      [[ $# -ge 2 ]] || { echo "Missing value for --codesign-identity." >&2; exit 64; }
      CODESIGN_IDENTITY="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: scripts/build_pushwrite_product.sh [output-dir|--output-dir path] [--qa] [--codesign-identity identity]"
      exit 0
      ;;
    --*)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
    *)
      if [[ "$OUTPUT_DIR_RAW" != "$DEFAULT_OUTPUT_DIR" ]]; then
        echo "Only one output directory may be supplied." >&2
        exit 64
      fi
      OUTPUT_DIR_RAW="$1"
      shift
      ;;
  esac
done

if [[ -L "$OUTPUT_DIR_RAW" ]]; then
  echo "Refusing symlink output directory: $OUTPUT_DIR_RAW" >&2
  exit 64
fi
OUTPUT_DIR="${OUTPUT_DIR_RAW:A}"
APP_DIR="$OUTPUT_DIR/PushWrite.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
ASSETS_DIR="$SOURCE_DIR/Assets"
APP_ICON="$ASSETS_DIR/PushWrite.icns"
WHISPER_RESOURCES_DIR="$RESOURCES_DIR/whisper"
WHISPER_BIN_DIR="$WHISPER_RESOURCES_DIR/bin"
WHISPER_MODELS_DIR="$WHISPER_RESOURCES_DIR/models"
WHISPER_LICENSES_DIR="$WHISPER_RESOURCES_DIR/licenses"
WHISPER_CLI_SOURCE="${WHISPER_CLI_SOURCE_OVERRIDE:-$ROOT_DIR/build/whispercpp/build/bin/whisper-cli}"
WHISPER_MODEL_SOURCE="$ROOT_DIR/models/ggml-large-v3-q5_0.bin"
LOCAL_TEXT_RESOURCES_DIR="$RESOURCES_DIR/local-text"
LOCAL_TEXT_BIN_DIR="$LOCAL_TEXT_RESOURCES_DIR/bin"
LOCAL_TEXT_MODELS_DIR="$LOCAL_TEXT_RESOURCES_DIR/models"
LOCAL_TEXT_LICENSES_DIR="$LOCAL_TEXT_RESOURCES_DIR/licenses"
LOCAL_TEXT_CLI_SOURCE="${LOCAL_TEXT_CLI_SOURCE_OVERRIDE:-$ROOT_DIR/build/llamacpp/build/bin/llama-completion}"
LOCAL_TEXT_MODEL_SOURCE="$ROOT_DIR/models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
LOCAL_TEXT_MODEL_LICENSE_SOURCE="$ROOT_DIR/models/Qwen2.5-LICENSE.txt"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
RUNTIME_INTEGRITY_SOURCE="$OUTPUT_DIR/RuntimeIntegrity.swift"
ICON_BUILDER="$OUTPUT_DIR/build_pushwrite_icon"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"
SWIFT_TARGET="${PUSHWRITE_SWIFT_TARGET:-arm64-apple-macos13.0}"
SWIFT_DEFINES=()

if [[ $QA_BUILD -eq 1 ]]; then
  SWIFT_DEFINES=(-D PUSHWRITE_QA_CONTROL_INTERFACE)
fi

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
if ! (cd "$ROOT_DIR" && shasum -a 256 -c "$ASSETS_DIR/whisper-model.sha256" >/dev/null); then
  echo "Whisper model integrity check failed." >&2
  exit 1
fi
if [[ ! -x "$LOCAL_TEXT_CLI_SOURCE" ]]; then
  echo "Missing llama-completion source at $LOCAL_TEXT_CLI_SOURCE" >&2
  echo "Build it first with scripts/build_llamacpp_minimal.sh." >&2
  exit 1
fi
if [[ -L "$WHISPER_CLI_SOURCE" || -L "$LOCAL_TEXT_CLI_SOURCE" ]]; then
  echo "Runtime executable sources must be regular files, not symlinks." >&2
  exit 1
fi
if [[ ! -f "$LOCAL_TEXT_MODEL_SOURCE" ]]; then
  echo "Missing local text model at $LOCAL_TEXT_MODEL_SOURCE" >&2
  echo "Fetch and verify it first with scripts/fetch_local_text_model.sh." >&2
  exit 1
fi
if [[ ! -f "$LOCAL_TEXT_MODEL_LICENSE_SOURCE" ]]; then
  echo "Missing Qwen2.5 license at $LOCAL_TEXT_MODEL_LICENSE_SOURCE" >&2
  echo "Fetch it first with scripts/fetch_local_text_model.sh." >&2
  exit 1
fi
if ! (cd "$ROOT_DIR/models" && shasum -a 256 -c "$ASSETS_DIR/local-text-model.sha256" >/dev/null); then
  echo "Local text model integrity check failed." >&2
  exit 1
fi
if ! (cd "$ROOT_DIR/models" && shasum -a 256 -c "$ASSETS_DIR/local-text-license.sha256" >/dev/null); then
  echo "Qwen2.5 license integrity check failed." >&2
  exit 1
fi
if otool -L "$LOCAL_TEXT_CLI_SOURCE" | grep -Eq '(libcurl|libssl|libcrypto)'; then
  echo "llama-completion must not link a network or TLS library." >&2
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
if [[ ! -f "$ENTITLEMENTS_PLIST" ]]; then
  echo "Missing app entitlements at $ENTITLEMENTS_PLIST" >&2
  exit 1
fi

if [[ -L "$APP_DIR" ]]; then
  echo "Refusing symlink application output: $APP_DIR" >&2
  exit 64
fi
rm -rf "$APP_DIR"
mkdir -p \
  "$MACOS_DIR" \
  "$WHISPER_BIN_DIR" \
  "$WHISPER_MODELS_DIR" \
  "$WHISPER_LICENSES_DIR" \
  "$LOCAL_TEXT_BIN_DIR" \
  "$LOCAL_TEXT_MODELS_DIR" \
  "$LOCAL_TEXT_LICENSES_DIR" \
  "$MODULE_CACHE_DIR"
cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
if [[ $QA_BUILD -eq 1 ]]; then
  /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier ch.baumanncreative.pushwrite.qa' "$APP_DIR/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleName PushWrite QA' "$APP_DIR/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName PushWrite QA' "$APP_DIR/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string PushWrite QA' "$APP_DIR/Contents/Info.plist"
fi
printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

cp "$WHISPER_CLI_SOURCE" "$WHISPER_BIN_DIR/whisper-cli"
chmod +x "$WHISPER_BIN_DIR/whisper-cli"
cp "$LOCAL_TEXT_CLI_SOURCE" "$LOCAL_TEXT_BIN_DIR/llama-completion"
chmod +x "$LOCAL_TEXT_BIN_DIR/llama-completion"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  codesign --force --options runtime --sign - "$WHISPER_BIN_DIR/whisper-cli"
  codesign --force --options runtime --sign - "$LOCAL_TEXT_BIN_DIR/llama-completion"
else
  codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$WHISPER_BIN_DIR/whisper-cli"
  codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$LOCAL_TEXT_BIN_DIR/llama-completion"
fi

WHISPER_CLI_SHA256="$(shasum -a 256 "$WHISPER_BIN_DIR/whisper-cli" | awk '{print $1}')"
LOCAL_TEXT_CLI_SHA256="$(shasum -a 256 "$LOCAL_TEXT_BIN_DIR/llama-completion" | awk '{print $1}')"
cat > "$RUNTIME_INTEGRITY_SOURCE" <<SWIFT
let bundledWhisperExecutableSHA256 = "$WHISPER_CLI_SHA256"
let bundledLocalTextExecutableSHA256 = "$LOCAL_TEXT_CLI_SHA256"
SWIFT

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -target "$SWIFT_TARGET" \
  -O \
  "${SWIFT_DEFINES[@]}" \
  -framework AppKit \
  -framework ApplicationServices \
  -framework AVFoundation \
  -framework Carbon \
  -framework CryptoKit \
  "$ROOT_DIR/core/workflow/PushWriteCore.swift" \
  "$RUNTIME_INTEGRITY_SOURCE" \
  "$SOURCE_DIR/ProductUI.swift" \
  "$SOURCE_DIR/main.swift" \
  -o "$MACOS_DIR/PushWrite"

cp "$WHISPER_MODEL_SOURCE" "$WHISPER_MODELS_DIR/ggml-large-v3-q5_0.bin"
cp "$LOCAL_TEXT_MODEL_SOURCE" "$LOCAL_TEXT_MODELS_DIR/qwen2.5-1.5b-instruct-q4_k_m.gguf"
cp "$ASSETS_DIR/local-text-model-manifest.json" "$LOCAL_TEXT_RESOURCES_DIR/model-manifest.json"
cp "$ASSETS_DIR/local-text-license.sha256" "$LOCAL_TEXT_RESOURCES_DIR/license.sha256"
cp "$LOCAL_TEXT_MODEL_LICENSE_SOURCE" "$LOCAL_TEXT_LICENSES_DIR/Qwen2.5-LICENSE.txt"
cp "$ROOT_DIR/third_party/llama.cpp/LICENSE" "$LOCAL_TEXT_LICENSES_DIR/llama.cpp-LICENSE.txt"
cp "$ASSETS_DIR/PushWriteMenuBarTemplate.svg" "$RESOURCES_DIR/PushWriteMenuBarTemplate.svg"
cp "$ASSETS_DIR/model-manifest.json" "$WHISPER_RESOURCES_DIR/model-manifest.json"
cp "$ROOT_DIR/third_party/whisper.cpp/LICENSE" "$WHISPER_LICENSES_DIR/whisper.cpp-LICENSE.txt"
cp "$ROOT_DIR/third_party/OpenAI-Whisper-LICENSE.txt" "$WHISPER_LICENSES_DIR/OpenAI-Whisper-LICENSE.txt"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$RESOURCES_DIR/THIRD_PARTY_NOTICES.md"
cp "$APP_ICON" "$RESOURCES_DIR/PushWrite.icns"

if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  codesign --force --options runtime --entitlements "$ENTITLEMENTS_PLIST" --sign - "$APP_DIR"
else
  codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS_PLIST" \
    --sign "$CODESIGN_IDENTITY" "$APP_DIR"
fi
"$ROOT_DIR/scripts/inspect_pushwrite_product_identity.sh" "$APP_DIR" "$OUTPUT_DIR/build-identity.txt" >/dev/null

printf '%s\n' "$APP_DIR"
