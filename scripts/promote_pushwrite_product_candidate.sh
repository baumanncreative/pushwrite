#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_OUTPUT_DIR="${${1:-$ROOT_DIR/build/pushwrite-product-candidate}:A}"
TARGET_OUTPUT_DIR="${${2:-$ROOT_DIR/build/pushwrite-product}:A}"
ARCHIVE_ROOT="${${3:-$ROOT_DIR/build/pushwrite-product-archive}:A}"
SOURCE_APP="$SOURCE_OUTPUT_DIR/PushWrite.app"
SOURCE_IDENTITY="$SOURCE_OUTPUT_DIR/build-identity.txt"
TARGET_APP="$TARGET_OUTPUT_DIR/PushWrite.app"
TARGET_IDENTITY="$TARGET_OUTPUT_DIR/bundle-identity.txt"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
ARCHIVE_DIR="$ARCHIVE_ROOT/$TIMESTAMP"
TMP_APP="$TARGET_OUTPUT_DIR/.PushWrite.app.promote-$TIMESTAMP"

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Missing candidate bundle at $SOURCE_APP" >&2
  exit 1
fi

if [[ "$SOURCE_APP" == "$TARGET_APP" ]]; then
  echo "Source and target app path are identical: $SOURCE_APP" >&2
  exit 64
fi

mkdir -p "$TARGET_OUTPUT_DIR" "$ARCHIVE_ROOT"

if [[ -d "$TARGET_APP" || -f "$TARGET_IDENTITY" ]]; then
  mkdir -p "$ARCHIVE_DIR"
  if [[ -d "$TARGET_APP" ]]; then
    ditto "$TARGET_APP" "$ARCHIVE_DIR/PushWrite.app"
  fi
  if [[ -f "$TARGET_IDENTITY" ]]; then
    cp "$TARGET_IDENTITY" "$ARCHIVE_DIR/bundle-identity.txt"
  fi
fi

rm -rf "$TMP_APP"
ditto "$SOURCE_APP" "$TMP_APP"
if [[ -d "$TARGET_APP" ]]; then
  rm -rf "$TARGET_APP"
fi
mv "$TMP_APP" "$TARGET_APP"

if [[ -f "$SOURCE_IDENTITY" ]]; then
  cp "$SOURCE_IDENTITY" "$TARGET_IDENTITY"
else
  "$ROOT_DIR/scripts/inspect_pushwrite_product_identity.sh" "$TARGET_APP" "$TARGET_IDENTITY" >/dev/null
fi

if [[ -d "$ARCHIVE_DIR" ]]; then
  echo "Archived previous stable bundle at $ARCHIVE_DIR" >&2
fi
echo "Promoted candidate bundle to $TARGET_APP" >&2
echo "If the CDHash changed, Accessibility trust must be re-granted for the stable bundle." >&2
printf '%s\n' "$TARGET_APP"
