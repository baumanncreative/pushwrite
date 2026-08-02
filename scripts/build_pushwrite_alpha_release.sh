#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/app/macos/PushWrite/Info.plist"
ENTITLEMENTS_PLIST="$ROOT_DIR/app/macos/PushWrite/PushWrite.entitlements"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
OUTPUT_ROOT="${1:-$ROOT_DIR/build/releases}"
RELEASE_DIR="${OUTPUT_ROOT:A}/PushWrite-${VERSION}"
PRODUCT_BUILD_DIR="$RELEASE_DIR/product-build"
APP_PATH="$RELEASE_DIR/PushWrite.app"
ZIP_PATH="$RELEASE_DIR/PushWrite-${VERSION}-macos-arm64.zip"
DMG_PATH="$RELEASE_DIR/PushWrite-${VERSION}-macos-arm64.dmg"
CHECKSUM_PATH="$RELEASE_DIR/SHA256SUMS.txt"
METADATA_PATH="$RELEASE_DIR/release-metadata.txt"
STAGING_DIR="$RELEASE_DIR/dmg-staging"
SIGNING_IDENTITY="${PUSHWRITE_CODESIGN_IDENTITY:-}"
NOTARY_PROFILE="${PUSHWRITE_NOTARY_PROFILE:-}"

mkdir -p "$RELEASE_DIR"
"$ROOT_DIR/scripts/build_pushwrite_product.sh" "$PRODUCT_BUILD_DIR" >/dev/null

rm -rf "$APP_PATH" "$STAGING_DIR"
rm -f "$ZIP_PATH" "$DMG_PATH" "$CHECKSUM_PATH" "$METADATA_PATH"
ditto "$PRODUCT_BUILD_DIR/PushWrite.app" "$APP_PATH"

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" \
    "$APP_PATH/Contents/Resources/whisper/bin/whisper-cli"
  codesign --force --deep --options runtime --timestamp --entitlements "$ENTITLEMENTS_PLIST" \
    --sign "$SIGNING_IDENTITY" "$APP_PATH"
fi

codesign --verify --deep --strict --verbose=4 "$APP_PATH"

if otool -L "$APP_PATH/Contents/Resources/whisper/bin/whisper-cli" | tail -n +2 | grep -F "$ROOT_DIR"; then
  echo "Bundled whisper-cli contains a repository-local dependency." >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/PushWrite.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create \
  -volname "PushWrite ${VERSION}" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

(
  cd "$RELEASE_DIR"
  shasum -a 256 "${ZIP_PATH:t}" "${DMG_PATH:t}" > "${CHECKSUM_PATH:t}"
)

APP_CDHASH="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1 | awk -F= '/^CDHash=/{print $2; exit}')"
BUNDLE_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
cat > "$METADATA_PATH" <<METADATA
version=$VERSION
build=$BUNDLE_BUILD
bundle_identifier=ch.baumanncreative.pushwrite
architecture=arm64
minimum_macos=13.0
signing_identity=${SIGNING_IDENTITY:-ad-hoc}
notarization_profile_configured=$([[ -n "$NOTARY_PROFILE" ]] && echo true || echo false)
app_cdhash=$APP_CDHASH
app_path=$APP_PATH
zip_path=$ZIP_PATH
dmg_path=$DMG_PATH
checksums_path=$CHECKSUM_PATH
METADATA

printf '%s\n' "$APP_PATH" "$ZIP_PATH" "$DMG_PATH" "$CHECKSUM_PATH" "$METADATA_PATH"
