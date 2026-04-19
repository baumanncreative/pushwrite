#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/app/macos/PushWrite/Info.plist"
PRODUCT_BUILD_SCRIPT="$ROOT_DIR/scripts/build_pushwrite_product.sh"
IDENTITY_SCRIPT="$ROOT_DIR/scripts/inspect_pushwrite_product_identity.sh"

usage() {
  cat <<USAGE
Usage: scripts/build_pushwrite_release_candidate.sh [options]

Options:
  --version <semver>       Version for naming (default: CFBundleShortVersionString from Info.plist)
  --rc <tag>               Release candidate tag (default: rc1)
  --output-root <path>     Output root (default: <repo>/build/release-candidates)
  --skip-product-build     Reuse existing product candidate build in output root
  -h, --help               Show this help
USAGE
}

VERSION=""
RC_TAG="rc1"
OUTPUT_ROOT="$ROOT_DIR/build/release-candidates"
SKIP_PRODUCT_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --rc)
      RC_TAG="$2"
      shift 2
      ;;
    --output-root)
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --skip-product-build)
      SKIP_PRODUCT_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
fi

if [[ -z "$VERSION" || -z "$RC_TAG" ]]; then
  echo "Version and RC tag must be non-empty." >&2
  exit 64
fi

RC_NAME="PushWrite-v${VERSION}-${RC_TAG}"
RC_DIR="${OUTPUT_ROOT:A}/${RC_NAME}"
BUILD_DIR="$RC_DIR/build"
PRODUCT_BUILD_OUTPUT_DIR="$BUILD_DIR/product-candidate"
PRODUCT_BUNDLE_PATH="$PRODUCT_BUILD_OUTPUT_DIR/PushWrite.app"
RC_APP_NAME="PushWrite.app"
RC_APP_PATH="$RC_DIR/$RC_APP_NAME"
LEGACY_RC_APP_PATH="$RC_DIR/${RC_NAME}.app"
RC_ARTIFACT_PATH="$RC_DIR/${RC_NAME}-macos.zip"
RC_IDENTITY_PATH="$RC_DIR/${RC_NAME}-identity.txt"
RC_METADATA_PATH="$RC_DIR/${RC_NAME}-metadata.txt"

if [[ $SKIP_PRODUCT_BUILD -eq 0 ]]; then
  mkdir -p "$BUILD_DIR"
  "$PRODUCT_BUILD_SCRIPT" "$PRODUCT_BUILD_OUTPUT_DIR" >/dev/null
fi

if [[ ! -d "$PRODUCT_BUNDLE_PATH" ]]; then
  echo "Missing product bundle at $PRODUCT_BUNDLE_PATH" >&2
  echo "Run without --skip-product-build or provide a valid existing candidate build." >&2
  exit 1
fi

rm -rf "$RC_APP_PATH" "$LEGACY_RC_APP_PATH"
rm -f "$RC_ARTIFACT_PATH" "$RC_IDENTITY_PATH" "$RC_METADATA_PATH"
mkdir -p "$RC_DIR"

ditto "$PRODUCT_BUNDLE_PATH" "$RC_APP_PATH"

INFO_PATH="$RC_APP_PATH/Contents/Info.plist"
EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PATH")"
BUNDLE_IDENTIFIER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PATH")"
EXECUTABLE_PATH="$RC_APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
BUNDLED_WHISPER_CLI_PATH="$RC_APP_PATH/Contents/Resources/whisper/bin/whisper-cli"
BUNDLED_WHISPER_MODEL_PATH="$RC_APP_PATH/Contents/Resources/whisper/models/ggml-tiny.bin"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Missing executable in release candidate bundle: $EXECUTABLE_PATH" >&2
  exit 1
fi
if [[ ! -x "$BUNDLED_WHISPER_CLI_PATH" ]]; then
  echo "Missing bundled whisper CLI in release candidate bundle: $BUNDLED_WHISPER_CLI_PATH" >&2
  exit 1
fi
if [[ ! -f "$BUNDLED_WHISPER_MODEL_PATH" ]]; then
  echo "Missing bundled whisper model in release candidate bundle: $BUNDLED_WHISPER_MODEL_PATH" >&2
  exit 1
fi

"$IDENTITY_SCRIPT" "$RC_APP_PATH" "$RC_IDENTITY_PATH" >/dev/null

CODESIGN_VERIFY_OUTPUT="$(codesign --verify --deep --strict --verbose=4 "$RC_APP_PATH" 2>&1 || true)"
if ! printf '%s' "$CODESIGN_VERIFY_OUTPUT" | grep -q "valid on disk"; then
  echo "codesign verification failed for $RC_APP_PATH" >&2
  echo "$CODESIGN_VERIFY_OUTPUT" >&2
  exit 1
fi

CDHASH="$(codesign -dv --verbose=4 "$RC_APP_PATH" 2>&1 | awk -F= '/^CDHash=/{print $2; exit}')"
if [[ -z "$CDHASH" ]]; then
  echo "Could not determine CDHash for $RC_APP_PATH" >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$RC_APP_PATH" "$RC_ARTIFACT_PATH"
if [[ ! -f "$RC_ARTIFACT_PATH" ]]; then
  echo "Release artifact was not created: $RC_ARTIFACT_PATH" >&2
  exit 1
fi

ARTIFACT_SHA256="$(shasum -a 256 "$RC_ARTIFACT_PATH" | awk '{print $1}')"
ARTIFACT_SIZE_BYTES="$(stat -f%z "$RC_ARTIFACT_PATH")"

cat > "$RC_METADATA_PATH" <<METADATA
created_at_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
release_candidate_name=$RC_NAME
release_candidate_version=$VERSION
release_candidate_tag=$RC_TAG
release_candidate_bundle_path=$RC_APP_PATH
release_candidate_artifact_path=$RC_ARTIFACT_PATH
release_candidate_artifact_sha256=$ARTIFACT_SHA256
release_candidate_artifact_size_bytes=$ARTIFACT_SIZE_BYTES
bundle_identifier=$BUNDLE_IDENTIFIER
bundle_executable=$EXECUTABLE_NAME
bundle_executable_path=$EXECUTABLE_PATH
bundled_whisper_cli_path=$BUNDLED_WHISPER_CLI_PATH
bundled_whisper_model_path=$BUNDLED_WHISPER_MODEL_PATH
bundle_cdhash=$CDHASH
bundle_identity_report=$RC_IDENTITY_PATH
codesign_verify_result=$(printf '%s' "$CODESIGN_VERIFY_OUTPUT" | tr '\n' ';' | sed 's/;\+$//')
METADATA

printf '%s\n' "release_candidate_name=$RC_NAME"
printf '%s\n' "release_candidate_bundle_path=$RC_APP_PATH"
printf '%s\n' "release_candidate_artifact_path=$RC_ARTIFACT_PATH"
printf '%s\n' "release_candidate_metadata_path=$RC_METADATA_PATH"
printf '%s\n' "bundle_identifier=$BUNDLE_IDENTIFIER"
printf '%s\n' "bundle_executable=$EXECUTABLE_NAME"
printf '%s\n' "bundle_cdhash=$CDHASH"
printf '%s\n' "bundled_whisper_cli_path=$BUNDLED_WHISPER_CLI_PATH"
printf '%s\n' "bundled_whisper_model_path=$BUNDLED_WHISPER_MODEL_PATH"
printf '%s\n' "artifact_sha256=$ARTIFACT_SHA256"
printf '%s\n' "artifact_size_bytes=$ARTIFACT_SIZE_BYTES"
