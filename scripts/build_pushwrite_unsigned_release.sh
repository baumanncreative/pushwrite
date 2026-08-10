#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/app/macos/PushWrite/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
OUTPUT_ROOT_RAW="${1:-$ROOT_DIR/build/releases}"
ACKNOWLEDGED="${PUSHWRITE_ACKNOWLEDGE_UNSIGNED_RELEASE:-}"

if [[ "$ACKNOWLEDGED" != "YES" ]]; then
  echo "Unsigned publication requires PUSHWRITE_ACKNOWLEDGE_UNSIGNED_RELEASE=YES." >&2
  echo "The resulting app is not Developer-ID signed or notarized and may require Gatekeeper's Open Anyway action." >&2
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
RELEASE_DIR="$OUTPUT_ROOT/PushWrite-$VERSION-unsigned"
if [[ -e "$RELEASE_DIR" || -L "$RELEASE_DIR" ]]; then
  echo "Release destination already exists; refusing to overwrite it: $RELEASE_DIR" >&2
  exit 64
fi

BUILD_ROOT="$(mktemp -d /tmp/pushwrite-unsigned-release-build.XXXXXXXX)"
STAGE_DIR="$(mktemp -d "$OUTPUT_ROOT/.PushWrite-$VERSION-unsigned.XXXXXXXX")"
cleanup() {
  if [[ "${DMG_ATTACHED:-0}" == "1" && -n "${DMG_MOUNT:-}" ]]; then
    /usr/bin/hdiutil detach "$DMG_MOUNT" >/dev/null 2>&1 || true
  fi
  case "$BUILD_ROOT" in
    /tmp/pushwrite-unsigned-release-build.*) rm -rf "$BUILD_ROOT" ;;
  esac
  if [[ -n "${STAGE_DIR:-}" && "$STAGE_DIR" == "$OUTPUT_ROOT"/.PushWrite-$VERSION-unsigned.* ]]; then
    rm -rf "$STAGE_DIR"
  fi
}
trap cleanup EXIT INT TERM

WHISPER_BUILD_ROOT="$BUILD_ROOT/whisper"
LOCAL_TEXT_BUILD_ROOT="$BUILD_ROOT/local-text"
PRODUCT_BUILD_ROOT="$BUILD_ROOT/product"
WHISPER_CLI="$(PUSHWRITE_DEPLOYMENT_TARGET=13.0 \
  "$ROOT_DIR/scripts/build_whispercpp_minimal.sh" "$WHISPER_BUILD_ROOT")"
LOCAL_TEXT_CLI="$(PUSHWRITE_DEPLOYMENT_TARGET=13.0 \
  "$ROOT_DIR/scripts/build_llamacpp_minimal.sh" "$LOCAL_TEXT_BUILD_ROOT")"

if [[ ! -x "$WHISPER_CLI" || ! -x "$LOCAL_TEXT_CLI" ]]; then
  echo "Fresh release runtime build did not produce both required executables." >&2
  exit 1
fi

PUSHWRITE_SWIFT_TARGET=arm64-apple-macos13.0 \
"$ROOT_DIR/scripts/build_pushwrite_product.sh" \
  "$PRODUCT_BUILD_ROOT" \
  --whisper-cli-source "$WHISPER_CLI" \
  --local-text-cli-source "$LOCAL_TEXT_CLI" >/dev/null

APP_PATH="$STAGE_DIR/PushWrite.app"
ZIP_NAME="PushWrite-$VERSION-macos-arm64-unsigned.zip"
DMG_NAME="PushWrite-$VERSION-macos-arm64-unsigned.dmg"
ZIP_PATH="$STAGE_DIR/$ZIP_NAME"
DMG_PATH="$STAGE_DIR/$DMG_NAME"
CHECKSUM_PATH="$STAGE_DIR/SHA256SUMS.txt"
METADATA_PATH="$STAGE_DIR/release-metadata.txt"
VALIDATION_PATH="$STAGE_DIR/install-validation.txt"
INSTALLATION_PATH="$STAGE_DIR/INSTALLATION.txt"
DMG_STAGING="$BUILD_ROOT/dmg-staging"

cat > "$INSTALLATION_PATH" <<INSTALLATION
PushWrite $VERSION wird direkt über GitHub und ohne Apple Developer ID oder Notarisierung verteilt.

1. Öffne das DMG und ziehe PushWrite.app auf Applications.
2. Starte PushWrite einmal.
3. Die erste macOS-Warnung bietet nur "In den Papierkorb legen" und "Fertig" an. Wähle "Fertig".
4. Öffne Systemeinstellungen > Datenschutz & Sicherheit.
5. Scrolle zu Sicherheit und wähle bei PushWrite "Dennoch öffnen". Bestätige danach "Öffnen".
6. Erlaube Mikrofon und Bedienungshilfen, sobald PushWrite danach fragt.

Ohne Apple Developer ID ist diese einmalige manuelle Freigabe technisch erforderlich.

Prüfe vor dem Öffnen die GitHub-Build-Attestierung und den unveränderlichen Release:

  gh attestation verify FILE -R baumanncreative/pushwrite --signer-workflow baumanncreative/pushwrite/.github/workflows/release.yml --source-ref refs/heads/main
  gh release verify-asset v$VERSION FILE -R baumanncreative/pushwrite

SHA256SUMS.txt erkennt zusätzlich versehentliche Übertragungsfehler.
INSTALLATION

/usr/bin/ditto "$PRODUCT_BUILD_ROOT/PushWrite.app" "$APP_PATH"
/usr/bin/codesign --verify --deep --strict --verbose=4 "$APP_PATH"
if ! /usr/bin/codesign -dvv "$APP_PATH" 2>&1 | /usr/bin/grep -F 'Signature=adhoc' >/dev/null; then
  echo "Unsigned release app does not have the expected ad-hoc structural signature." >&2
  exit 1
fi
if ! /usr/bin/codesign -dvv "$APP_PATH" 2>&1 | /usr/bin/grep -Fx 'TeamIdentifier=not set' >/dev/null; then
  echo "Unsigned release unexpectedly contains an Apple TeamIdentifier." >&2
  exit 1
fi
for executable in \
  "$APP_PATH/Contents/MacOS/PushWrite" \
  "$APP_PATH/Contents/Resources/whisper/bin/whisper-cli" \
  "$APP_PATH/Contents/Resources/local-text/bin/llama-completion"; do
  if [[ "$(/usr/bin/lipo -archs "$executable")" != "arm64" ]]; then
    echo "Release executable is not exactly arm64: $executable" >&2
    exit 1
  fi
  if [[ "$(/usr/bin/vtool -show-build "$executable" | awk '/^[[:space:]]*minos /{print $2; exit}')" != "13.0" ]]; then
    echo "Release executable does not declare macOS 13.0 as its minimum version: $executable" >&2
    exit 1
  fi
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
for consumed_build_root in "$WHISPER_BUILD_ROOT" "$LOCAL_TEXT_BUILD_ROOT" "$PRODUCT_BUILD_ROOT"; do
  if [[ "$consumed_build_root" == "$BUILD_ROOT"/* ]]; then
    rm -rf "$consumed_build_root"
  fi
done

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
mkdir -m 700 -p "$DMG_STAGING"
/usr/bin/ditto "$APP_PATH" "$DMG_STAGING/PushWrite.app"
/bin/ln -s /Applications "$DMG_STAGING/Applications"
/bin/cp "$INSTALLATION_PATH" "$DMG_STAGING/INSTALLIEREN.txt"
/usr/bin/hdiutil create \
  -volname "PushWrite $VERSION" \
  -srcfolder "$DMG_STAGING" \
  -format UDZO \
  "$DMG_PATH" >/dev/null
if [[ "$DMG_STAGING" == "$BUILD_ROOT"/* ]]; then
  rm -rf "$DMG_STAGING"
fi

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

GITHUB_ASSET_LIMIT_BYTES=2147483648
ZIP_SIZE_BYTES="$(/usr/bin/stat -f '%z' "$ZIP_PATH")"
DMG_SIZE_BYTES="$(/usr/bin/stat -f '%z' "$DMG_PATH")"
if (( ZIP_SIZE_BYTES >= GITHUB_ASSET_LIMIT_BYTES || DMG_SIZE_BYTES >= GITHUB_ASSET_LIMIT_BYTES )); then
  echo "A release asset meets or exceeds GitHub's 2 GiB per-file limit." >&2
  echo "ZIP bytes: $ZIP_SIZE_BYTES; DMG bytes: $DMG_SIZE_BYTES" >&2
  exit 1
fi

ZIP_SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
DMG_SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
/usr/bin/env -u PUSHWRITE_EXPECTED_TEAM_ID \
  "$ROOT_DIR/scripts/validate_pushwrite_release_candidate_install.sh" \
  --artifact-zip "$ZIP_PATH" \
  --expected-sha256 "$ZIP_SHA256" \
  --install-root "$BUILD_ROOT/install-validation" \
  --runtime-root "$BUILD_ROOT/runtime-validation" \
  --results-file "$VALIDATION_PATH" >/dev/null
for validation_root in "$BUILD_ROOT/install-validation" "$BUILD_ROOT/runtime-validation"; do
  if [[ "$validation_root" == "$BUILD_ROOT"/* ]]; then
    rm -rf "$validation_root"
  fi
done

DMG_MOUNT="$BUILD_ROOT/dmg-mount"
mkdir -m 700 "$DMG_MOUNT"
/usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$DMG_MOUNT" "$DMG_PATH" >/dev/null
DMG_ATTACHED=1
DMG_APP="$DMG_MOUNT/PushWrite.app"
if [[ ! -d "$DMG_APP" || ! -L "$DMG_MOUNT/Applications" || "$(/usr/bin/readlink "$DMG_MOUNT/Applications")" != "/Applications" ]]; then
  echo "Mounted DMG does not contain the expected app and Applications link." >&2
  exit 1
fi
if [[ ! -f "$DMG_MOUNT/INSTALLIEREN.txt" ]] \
  || ! /usr/bin/grep -F 'Datenschutz & Sicherheit' "$DMG_MOUNT/INSTALLIEREN.txt" >/dev/null \
  || ! /usr/bin/grep -F 'Dennoch öffnen' "$DMG_MOUNT/INSTALLIEREN.txt" >/dev/null; then
  echo "Mounted DMG does not contain the required Gatekeeper installation guidance." >&2
  exit 1
fi
DMG_TOP_LEVEL_COUNT="$(/usr/bin/find "$DMG_MOUNT" -mindepth 1 -maxdepth 1 ! -name '.Trashes' | /usr/bin/wc -l | tr -d ' ')"
if [[ "$DMG_TOP_LEVEL_COUNT" != "3" ]]; then
  echo "Mounted DMG contains unexpected top-level entries." >&2
  exit 1
fi
/usr/bin/codesign --verify --deep --strict "$DMG_APP"
if ! /usr/bin/codesign -dvv "$DMG_APP" 2>&1 | /usr/bin/grep -F 'Signature=adhoc' >/dev/null \
  || ! /usr/bin/codesign -dvv "$DMG_APP" 2>&1 | /usr/bin/grep -Fx 'TeamIdentifier=not set' >/dev/null; then
  echo "Mounted DMG app does not preserve the expected ad-hoc signature mode." >&2
  exit 1
fi
for relative_payload in \
  Contents/MacOS/PushWrite \
  Contents/Resources/PushWrite.icns \
  Contents/Resources/whisper/bin/whisper-cli \
  Contents/Resources/whisper/models/ggml-large-v3-q5_0.bin \
  Contents/Resources/local-text/bin/llama-completion \
  Contents/Resources/local-text/models/qwen2.5-1.5b-instruct-q4_k_m.gguf; do
  if [[ "$(shasum -a 256 "$DMG_APP/$relative_payload" | awk '{print $1}')" != \
        "$(shasum -a 256 "$APP_PATH/$relative_payload" | awk '{print $1}')" ]]; then
    echo "Mounted DMG payload differs from the validated release app: $relative_payload" >&2
    exit 1
  fi
done
/usr/bin/hdiutil detach "$DMG_MOUNT" >/dev/null
DMG_ATTACHED=0

(
  cd "$STAGE_DIR"
  shasum -a 256 "$ZIP_NAME" "$DMG_NAME" > "${CHECKSUM_PATH:t}"
)

APP_CDHASH="$(/usr/bin/codesign -dv --verbose=4 "$APP_PATH" 2>&1 | awk -F= '/^CDHash=/{print $2; exit}')"
APP_ICON_SHA256="$(shasum -a 256 "$APP_PATH/Contents/Resources/PushWrite.icns" | awk '{print $1}')"
BUNDLE_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"
cat > "$METADATA_PATH" <<METADATA
version=$VERSION
build=$BUNDLE_BUILD
bundle_identifier=ch.baumanncreative.pushwrite
architecture=arm64
minimum_macos=13.0
distribution=github-direct
signing_identity=ad-hoc
developer_id_signed=false
notarized=false
stapled=false
gatekeeper_override_may_be_required=true
distribution_authentication=github-actions-sigstore-attestation
immutable_github_release_required=true
app_cdhash=$APP_CDHASH
app_icon_sha256=$APP_ICON_SHA256
zip_name=$ZIP_NAME
zip_sha256=$ZIP_SHA256
zip_size_bytes=$ZIP_SIZE_BYTES
dmg_name=$DMG_NAME
dmg_sha256=$DMG_SHA256
dmg_size_bytes=$DMG_SIZE_BYTES
github_asset_limit_bytes=$GITHUB_ASSET_LIMIT_BYTES
fresh_runtime_build=true
production_qa_interface=false
METADATA

/bin/mv "$STAGE_DIR" "$RELEASE_DIR"
STAGE_DIR=""
trap - EXIT INT TERM
case "$BUILD_ROOT" in
  /tmp/pushwrite-unsigned-release-build.*) rm -rf "$BUILD_ROOT" ;;
esac

printf '%s\n' \
  "$RELEASE_DIR/PushWrite.app" \
  "$RELEASE_DIR/$ZIP_NAME" \
  "$RELEASE_DIR/$DMG_NAME" \
  "$RELEASE_DIR/SHA256SUMS.txt" \
  "$RELEASE_DIR/release-metadata.txt" \
  "$RELEASE_DIR/install-validation.txt" \
  "$RELEASE_DIR/INSTALLATION.txt"
