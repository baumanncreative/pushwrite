#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCTION_APP="${1:-$ROOT_DIR/build/security-production-check/PushWrite.app}"
QA_APP="${2:-$ROOT_DIR/build/security-qa-check/PushWrite.app}"

if [[ ! -d "$PRODUCTION_APP" || ! -d "$QA_APP" ]]; then
  echo "Usage: scripts/run_pushwrite_security_regression_tests.sh <production-app> <qa-app>" >&2
  exit 64
fi

PRODUCTION_BINARY="$PRODUCTION_APP/Contents/MacOS/PushWrite"
QA_BINARY="$QA_APP/Contents/MacOS/PushWrite"
PRODUCTION_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PRODUCTION_APP/Contents/Info.plist")"
QA_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$QA_APP/Contents/Info.plist")"

if [[ "$PRODUCTION_BUNDLE_ID" != "ch.baumanncreative.pushwrite" ]]; then
  echo "Unexpected production bundle identifier: $PRODUCTION_BUNDLE_ID" >&2
  exit 1
fi
if [[ "$QA_BUNDLE_ID" != "ch.baumanncreative.pushwrite.qa" ]]; then
  echo "Unexpected QA bundle identifier: $QA_BUNDLE_ID" >&2
  exit 1
fi

if /usr/bin/strings "$PRODUCTION_BINARY" | /usr/bin/grep -F 'PUSHWRITE_' >/dev/null; then
  echo "Production executable contains a QA or runtime override marker." >&2
  exit 1
fi
if ! /usr/bin/strings "$QA_BINARY" | /usr/bin/grep -F PUSHWRITE_ENABLE_CONTROL_INTERFACE >/dev/null; then
  echo "QA executable is missing its compile-time control interface." >&2
  exit 1
fi

REVISION="48c389fb6b88c8e80f03273a677a422729183e06"
VALID_AUDIO_URL="https://datasets-server.huggingface.co/assets/i4ds/SPC_test/--/$REVISION/--/default/test/0/audio/audio.wav?Expires=1&Signature=test&Key-Pair-Id=test"
if ! python3 "$ROOT_DIR/scripts/validate_swiss_asr_audio_url.py" "$VALID_AUDIO_URL" "$REVISION" 0; then
  echo "Swiss ASR URL validator rejected its positive control." >&2
  exit 1
fi
INVALID_AUDIO_URLS=(
  "http://datasets-server.huggingface.co/assets/i4ds/SPC_test/--/$REVISION/--/default/test/0/audio/audio.wav?Expires=1&Signature=test&Key-Pair-Id=test"
  "https://127.0.0.1/assets/i4ds/SPC_test/--/$REVISION/--/default/test/0/audio/audio.wav?Expires=1&Signature=test&Key-Pair-Id=test"
  "https://datasets-server.huggingface.co/assets/i4ds/SPC_test/--/$REVISION/--/default/test/1/audio/audio.wav?Expires=1&Signature=test&Key-Pair-Id=test"
  "https://datasets-server.huggingface.co/assets/i4ds/SPC_test/--/$REVISION/--/default/test/0/audio/audio.wav?Expires=1&Signature=test&Key-Pair-Id=test#redirect"
)
for invalid_url in "${INVALID_AUDIO_URLS[@]}"; do
  if python3 "$ROOT_DIR/scripts/validate_swiss_asr_audio_url.py" "$invalid_url" "$REVISION" 0; then
    echo "Swiss ASR URL validator accepted a negative control." >&2
    exit 1
  fi
done

if ! /usr/bin/grep -F 'focusElement: AXUIElement?' "$ROOT_DIR/app/macos/PushWrite/main.swift" >/dev/null \
  || ! /usr/bin/grep -F 'focusElementAtStart: AXUIElement?' "$ROOT_DIR/app/macos/PushWrite/main.swift" >/dev/null \
  || ! /usr/bin/grep -F 'CFEqual(receiptElement, $0)' "$ROOT_DIR/app/macos/PushWrite/main.swift" >/dev/null; then
  echo "Receipt-time AX element binding is missing from the production source." >&2
  exit 1
fi

if /usr/bin/grep -F 'SHARED_LOCAL_CMAKE' "$ROOT_DIR/scripts/build_whispercpp_minimal.sh" "$ROOT_DIR/scripts/build_llamacpp_minimal.sh" >/dev/null; then
  echo "A native runtime builder still selects the mutable shared CMake cache." >&2
  exit 1
fi

if [[ "$(/usr/bin/grep -c -- '--max-filesize' "$ROOT_DIR/scripts/run_swiss_german_asr_validation.sh")" -lt 3 ]]; then
  echo "Swiss ASR validation is missing pre-write byte limits." >&2
  exit 1
fi

if [[ -e "$ROOT_DIR/app/macos/PushWriteInsertAgent" ]] \
  || [[ -e "$ROOT_DIR/scripts/control_pushwrite_insert_agent.swift" ]]; then
  echo "The retired unauthenticated Accessibility insert agent is still present." >&2
  exit 1
fi

if /usr/bin/strings "$PRODUCTION_BINARY" | /usr/bin/grep -F 'AVAudioRecorder' >/dev/null \
  || /usr/bin/strings "$PRODUCTION_BINARY" | /usr/bin/grep -F '.local-text-prompt-' >/dev/null; then
  echo "Production still contains a disk-backed sensitive recording or prompt path." >&2
  exit 1
fi
if ! /usr/bin/grep -F '"-f", "-"' "$ROOT_DIR/app/macos/PushWrite/main.swift" >/dev/null \
  || ! /usr/bin/grep -F '"--file", "/dev/stdin"' "$ROOT_DIR/app/macos/PushWrite/main.swift" >/dev/null; then
  echo "Production child runtimes are not wired to in-memory pipes." >&2
  exit 1
fi

SCRATCH_ROOT="$(mktemp -d /tmp/pushwrite-security-regression.XXXXXXXX)"
trap 'rm -rf "$SCRATCH_ROOT"' EXIT INT TERM

mkdir -m 700 "$SCRATCH_ROOT/existing-product-runtime" "$SCRATCH_ROOT/existing-hotkey-success" "$SCRATCH_ROOT/existing-hotkey-blocked"
printf '%s\n' "must-survive" > "$SCRATCH_ROOT/existing-product-runtime/sentinel"
if "$ROOT_DIR/scripts/run_pushwrite_product_validation.swift" \
  --product-runtime-dir "$SCRATCH_ROOT/existing-product-runtime" \
  --skip-build --skip-launch >/dev/null 2>&1; then
  echo "Product validator accepted an existing caller-selected scratch root." >&2
  exit 1
fi
if [[ "$(<"$SCRATCH_ROOT/existing-product-runtime/sentinel")" != "must-survive" ]]; then
  echo "Product validator modified an existing caller-selected scratch root." >&2
  exit 1
fi
if "$ROOT_DIR/scripts/run_pushwrite_hotkey_validation.swift" \
  --success-runtime-dir "$SCRATCH_ROOT/existing-hotkey-success" \
  --blocked-runtime-dir "$SCRATCH_ROOT/existing-hotkey-blocked" \
  --skip-build --skip-launch >/dev/null 2>&1; then
  echo "Hotkey validator accepted existing caller-selected scratch roots." >&2
  exit 1
fi

if env -u PUSHWRITE_CODESIGN_IDENTITY -u PUSHWRITE_NOTARY_PROFILE -u PUSHWRITE_TEAM_ID \
  "$ROOT_DIR/scripts/build_pushwrite_release.sh" "$SCRATCH_ROOT/release-must-not-exist" >/dev/null 2>&1; then
  echo "Stable release builder accepted missing signing or notarization configuration." >&2
  exit 1
fi
if [[ -e "$SCRATCH_ROOT/release-must-not-exist" ]]; then
  echo "Stable release builder created output before authenticating release configuration." >&2
  exit 1
fi

if ! /usr/bin/strings "$PRODUCTION_BINARY" | /usr/bin/grep -F '(deny network*) (deny file-write*) (allow file-write-data)' >/dev/null; then
  echo "Production child runtimes are missing network and file-write sandbox denial." >&2
  exit 1
fi
for runtime in \
  "$PRODUCTION_APP/Contents/Resources/whisper/bin/whisper-cli" \
  "$PRODUCTION_APP/Contents/Resources/local-text/bin/llama-completion"; do
  runtime_digest="$(shasum -a 256 "$runtime" | awk '{print $1}')"
  if ! /usr/bin/strings "$PRODUCTION_BINARY" | /usr/bin/grep -F "$runtime_digest" >/dev/null; then
    echo "Production executable is missing the pinned digest for $runtime." >&2
    exit 1
  fi
done
if /usr/bin/grep -F 'opaqueUnicodeKeyboardEvents' "$ROOT_DIR/app/macos/PushWrite/main.swift" >/dev/null; then
  echo "The unverified Codex opaque insertion route is still reachable." >&2
  exit 1
fi

mkdir -m 700 "$SCRATCH_ROOT/fake-bin"
/bin/cp /usr/bin/true "$SCRATCH_ROOT/fake-bin/cmake"
if PATH="$SCRATCH_ROOT/fake-bin:/usr/bin:/bin" "$ROOT_DIR/scripts/resolve_verified_cmake.sh" >/dev/null 2>&1; then
  echo "CMake resolver accepted an unsigned PATH executable." >&2
  exit 1
fi
mkdir -m 700 "$SCRATCH_ROOT/archive"
printf '%s\n' "untrusted" > "$SCRATCH_ROOT/archive/payload.txt"
(
  cd "$SCRATCH_ROOT/archive"
  /usr/bin/zip -q "$SCRATCH_ROOT/untrusted.zip" payload.txt
)
INSTALL_ROOT="$SCRATCH_ROOT/install-must-not-exist"
if "$ROOT_DIR/scripts/validate_pushwrite_release_candidate_install.sh" \
  --artifact-zip "$SCRATCH_ROOT/untrusted.zip" \
  --expected-sha256 0000000000000000000000000000000000000000000000000000000000000000 \
  --install-root "$INSTALL_ROOT" >/dev/null 2>&1; then
  echo "Archive validator accepted an unexpected digest." >&2
  exit 1
fi
if [[ -e "$INSTALL_ROOT" || -L "$INSTALL_ROOT" ]]; then
  echo "Archive validator extracted content before authenticating its digest." >&2
  exit 1
fi

printf '%s\n' "PushWrite security regression tests: passed"
