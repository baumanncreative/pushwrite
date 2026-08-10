#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/app/macos/PushWrite/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
OUTPUT_ROOT_RAW="${1:-$ROOT_DIR/build/releases}"
SIGNING_IDENTITY="${PUSHWRITE_CODESIGN_IDENTITY:-}"
NOTARY_PROFILE="${PUSHWRITE_NOTARY_PROFILE:-}"
EXPECTED_TEAM_ID="${PUSHWRITE_TEAM_ID:-}"

if [[ -z "$SIGNING_IDENTITY" || -z "$NOTARY_PROFILE" || -z "$EXPECTED_TEAM_ID" ]]; then
  echo "Stable releases require PUSHWRITE_CODESIGN_IDENTITY, PUSHWRITE_NOTARY_PROFILE, and PUSHWRITE_TEAM_ID." >&2
  exit 78
fi
if ! printf '%s' "$EXPECTED_TEAM_ID" | /usr/bin/grep -Eq '^[A-Z0-9]{10}$'; then
  echo "PUSHWRITE_TEAM_ID must be an exact 10-character Apple Team ID." >&2
  exit 64
fi
if ! /usr/bin/security find-identity -v -p codesigning \
  | /usr/bin/grep -F -- "\"$SIGNING_IDENTITY\"" >/dev/null; then
  echo "The configured Developer ID Application identity is not available: $SIGNING_IDENTITY" >&2
  exit 78
fi
if [[ "$SIGNING_IDENTITY" != Developer\ ID\ Application:* ]]; then
  echo "Stable releases require a Developer ID Application identity." >&2
  exit 78
fi

if ! printf '%s' "$VERSION" | /usr/bin/grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Release version must be a stable semantic version: $VERSION" >&2
  exit 64
fi
if [[ -L "$OUTPUT_ROOT_RAW" ]]; then
  echo "Refusing symlink release output root: $OUTPUT_ROOT_RAW" >&2
  exit 64
fi
mkdir -p "$OUTPUT_ROOT_RAW"
OUTPUT_ROOT="${OUTPUT_ROOT_RAW:A}"
RELEASE_DIR="$OUTPUT_ROOT/PushWrite-$VERSION"
if [[ -e "$RELEASE_DIR" || -L "$RELEASE_DIR" ]]; then
  echo "Release destination already exists; refusing to overwrite it: $RELEASE_DIR" >&2
  exit 64
fi

BUILD_ROOT="$(mktemp -d /tmp/pushwrite-release-build.XXXXXXXX)"
STAGE_DIR="$(mktemp -d "$OUTPUT_ROOT/.PushWrite-$VERSION.XXXXXXXX")"
cleanup() {
  case "$BUILD_ROOT" in
    /tmp/pushwrite-release-build.*) rm -rf "$BUILD_ROOT" ;;
  esac
  if [[ -n "${STAGE_DIR:-}" && "$STAGE_DIR" == "$OUTPUT_ROOT"/.PushWrite-$VERSION.* ]]; then
    rm -rf "$STAGE_DIR"
  fi
}
trap cleanup EXIT INT TERM

WHISPER_BUILD_ROOT="$BUILD_ROOT/whisper"
LOCAL_TEXT_BUILD_ROOT="$BUILD_ROOT/local-text"
PRODUCT_BUILD_ROOT="$BUILD_ROOT/product"
WHISPER_CLI="$($ROOT_DIR/scripts/build_whispercpp_minimal.sh "$WHISPER_BUILD_ROOT")"
LOCAL_TEXT_CLI="$($ROOT_DIR/scripts/build_llamacpp_minimal.sh "$LOCAL_TEXT_BUILD_ROOT")"

if [[ ! -x "$WHISPER_CLI" || ! -x "$LOCAL_TEXT_CLI" ]]; then
  echo "Fresh release runtime build did not produce both required executables." >&2
  exit 1
fi

"$ROOT_DIR/scripts/build_pushwrite_product.sh" \
  "$PRODUCT_BUILD_ROOT" \
  --whisper-cli-source "$WHISPER_CLI" \
  --local-text-cli-source "$LOCAL_TEXT_CLI" \
  --codesign-identity "$SIGNING_IDENTITY" >/dev/null

APP_PATH="$STAGE_DIR/PushWrite.app"
ZIP_NAME="PushWrite-$VERSION-macos-arm64.zip"
DMG_NAME="PushWrite-$VERSION-macos-arm64.dmg"
ZIP_PATH="$STAGE_DIR/$ZIP_NAME"
DMG_PATH="$STAGE_DIR/$DMG_NAME"
CHECKSUM_PATH="$STAGE_DIR/SHA256SUMS.txt"
METADATA_PATH="$STAGE_DIR/release-metadata.txt"
VALIDATION_PATH="$STAGE_DIR/install-validation.txt"
DMG_STAGING="$BUILD_ROOT/dmg-staging"

/usr/bin/ditto "$PRODUCT_BUILD_ROOT/PushWrite.app" "$APP_PATH"

/usr/bin/codesign --verify --deep --strict --verbose=4 "$APP_PATH"
ACTUAL_TEAM_ID="$(/usr/bin/codesign -dvv "$APP_PATH" 2>&1 | awk -F= '/^TeamIdentifier=/{print $2; exit}')"
if [[ "$ACTUAL_TEAM_ID" != "$EXPECTED_TEAM_ID" ]]; then
  echo "Signed app TeamIdentifier mismatch: expected $EXPECTED_TEAM_ID, got ${ACTUAL_TEAM_ID:-missing}." >&2
  exit 1
fi
for executable in \
  "$APP_PATH/Contents/Resources/whisper/bin/whisper-cli" \
  "$APP_PATH/Contents/Resources/local-text/bin/llama-completion"; do
  if /usr/bin/otool -L "$executable" | tail -n +2 | /usr/bin/grep -F "$ROOT_DIR"; then
    echo "Bundled runtime contains a repository-local dependency: $executable" >&2
    exit 1
  fi
done
if /usr/bin/otool -L "$APP_PATH/Contents/Resources/local-text/bin/llama-completion" \
  | /usr/bin/grep -Eq '(libcurl|libssl|libcrypto)'; then
  echo "Bundled local text runtime unexpectedly links a network or TLS library." >&2
  exit 1
fi

NOTARY_ZIP="$BUILD_ROOT/PushWrite-notary-submission.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP"
/usr/bin/xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$APP_PATH"
/usr/bin/xcrun stapler validate "$APP_PATH"
/usr/bin/spctl --assess --type execute --verbose=4 "$APP_PATH"

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
mkdir -m 700 -p "$DMG_STAGING"
/usr/bin/ditto "$APP_PATH" "$DMG_STAGING/PushWrite.app"
/bin/ln -s /Applications "$DMG_STAGING/Applications"
/usr/bin/hdiutil create \
  -volname "PushWrite $VERSION" \
  -srcfolder "$DMG_STAGING" \
  -format UDZO \
  "$DMG_PATH" >/dev/null

/usr/bin/codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
/usr/bin/xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$DMG_PATH"
/usr/bin/xcrun stapler validate "$DMG_PATH"
/usr/bin/spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
DMG_VERIFIED=0
for attempt in 1 2 3 4 5; do
  if /usr/bin/hdiutil verify "$DMG_PATH" >/dev/null; then
    DMG_VERIFIED=1
    break
  fi
  sleep 2
done
if (( DMG_VERIFIED != 1 )); then
  echo "DMG verification failed after 5 attempts: $DMG_PATH" >&2
  exit 1
fi

ZIP_SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
PUSHWRITE_EXPECTED_TEAM_ID="$EXPECTED_TEAM_ID" \
  "$ROOT_DIR/scripts/validate_pushwrite_release_candidate_install.sh" \
  --artifact-zip "$ZIP_PATH" \
  --expected-sha256 "$ZIP_SHA256" \
  --results-file "$VALIDATION_PATH" >/dev/null

(
  cd "$STAGE_DIR"
  shasum -a 256 "$ZIP_NAME" "$DMG_NAME" > "${CHECKSUM_PATH:t}"
)

APP_CDHASH="$(/usr/bin/codesign -dv --verbose=4 "$APP_PATH" 2>&1 | awk -F= '/^CDHash=/{print $2; exit}')"
BUNDLE_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
cat > "$METADATA_PATH" <<METADATA
version=$VERSION
build=$BUNDLE_BUILD
bundle_identifier=ch.baumanncreative.pushwrite
architecture=arm64
minimum_macos=13.0
signing_identity=$SIGNING_IDENTITY
team_identifier=$ACTUAL_TEAM_ID
notarized=true
stapled=true
app_cdhash=$APP_CDHASH
zip_name=$ZIP_NAME
zip_sha256=$ZIP_SHA256
dmg_name=$DMG_NAME
fresh_runtime_build=true
production_qa_interface=false
METADATA

/bin/mv "$STAGE_DIR" "$RELEASE_DIR"
STAGE_DIR=""
trap - EXIT INT TERM
case "$BUILD_ROOT" in
  /tmp/pushwrite-release-build.*) rm -rf "$BUILD_ROOT" ;;
esac

printf '%s\n' \
  "$RELEASE_DIR/PushWrite.app" \
  "$RELEASE_DIR/$ZIP_NAME" \
  "$RELEASE_DIR/$DMG_NAME" \
  "$RELEASE_DIR/SHA256SUMS.txt" \
  "$RELEASE_DIR/release-metadata.txt" \
  "$RELEASE_DIR/install-validation.txt"
