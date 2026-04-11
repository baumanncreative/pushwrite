#!/bin/zsh

set -euo pipefail

APP_PATH="${1:-}"
OUTPUT_FILE="${2:-}"

if [[ -z "$APP_PATH" ]]; then
  echo "Usage: scripts/inspect_pushwrite_product_identity.sh /abs/path/PushWrite.app [output-file]" >&2
  exit 64
fi

APP_PATH="${APP_PATH:A}"
INFO_PLIST="$APP_PATH/Contents/Info.plist"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle at $APP_PATH" >&2
  exit 1
fi

if [[ ! -f "$INFO_PLIST" ]]; then
  echo "Missing Info.plist at $INFO_PLIST" >&2
  exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
REPORT="$(cat <<EOF
captured_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
app_path=$APP_PATH
bundle_id=$BUNDLE_ID

[codesign -dv --verbose=4]
$(codesign -dv --verbose=4 "$APP_PATH" 2>&1)

[codesign -dr -]
$(codesign -dr - "$APP_PATH" 2>&1)
EOF
)"

if [[ -n "$OUTPUT_FILE" ]]; then
  OUTPUT_FILE="${OUTPUT_FILE:A}"
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  print -r -- "$REPORT" > "$OUTPUT_FILE"
fi

print -r -- "$REPORT"
