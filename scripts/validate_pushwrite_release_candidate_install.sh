#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTROL_SCRIPT="$ROOT_DIR/scripts/control_pushwrite_product.sh"
HOTKEY_VALIDATION_SCRIPT="$ROOT_DIR/scripts/run_pushwrite_hotkey_validation.sh"
TRANSCRIPTION_VALIDATION_SCRIPT="$ROOT_DIR/scripts/run_pushwrite_transcription_insert_validation.sh"
INFO_PLIST="$ROOT_DIR/app/macos/PushWrite/Info.plist"

usage() {
  cat <<USAGE
Usage: scripts/validate_pushwrite_release_candidate_install.sh [options]

Options:
  --artifact-zip <path>     Path to release zip artifact (required)
  --install-root <path>     Install extraction root (default: /tmp/pushwrite-rc-install)
  --runtime-root <path>     Runtime/log root (default: /tmp/pushwrite-rc-validation)
  --results-file <path>     Optional summary output file
  -h, --help                Show this help
USAGE
}

ARTIFACT_ZIP=""
INSTALL_ROOT="/tmp/pushwrite-rc-install"
RUNTIME_ROOT="/tmp/pushwrite-rc-validation"
RESULTS_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-zip)
      ARTIFACT_ZIP="$2"
      shift 2
      ;;
    --install-root)
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --runtime-root)
      RUNTIME_ROOT="$2"
      shift 2
      ;;
    --results-file)
      RESULTS_FILE="$2"
      shift 2
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

if [[ -z "$ARTIFACT_ZIP" ]]; then
  echo "Missing required --artifact-zip argument." >&2
  usage >&2
  exit 64
fi

ARTIFACT_ZIP="${ARTIFACT_ZIP:A}"
INSTALL_ROOT="${INSTALL_ROOT:A}"
RUNTIME_ROOT="${RUNTIME_ROOT:A}"

if [[ ! -f "$ARTIFACT_ZIP" ]]; then
  echo "Missing release artifact: $ARTIFACT_ZIP" >&2
  exit 1
fi

wait_for_file() {
  local path="$1"
  local timeout_seconds="${2:-15}"
  local waited=0
  while [[ ! -f "$path" ]]; do
    sleep 0.2
    waited=$((waited + 1))
    if (( waited >= timeout_seconds * 5 )); then
      echo "Timed out waiting for file: $path" >&2
      return 1
    fi
  done
}

read_json_raw() {
  local key="$1"
  local file="$2"
  /usr/bin/plutil -extract "$key" raw -o - "$file" 2>/dev/null || true
}

EXPECTED_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
EXPECTED_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"

rm -rf "$INSTALL_ROOT" "$RUNTIME_ROOT"
mkdir -p "$INSTALL_ROOT" "$RUNTIME_ROOT"

ditto -x -k "$ARTIFACT_ZIP" "$INSTALL_ROOT"

INSTALLED_APP_PATH="$(find "$INSTALL_ROOT" -maxdepth 2 -type d -name '*.app' | head -n 1)"
if [[ -z "$INSTALLED_APP_PATH" ]]; then
  echo "No .app bundle found after extracting $ARTIFACT_ZIP to $INSTALL_ROOT" >&2
  exit 1
fi
INSTALLED_APP_PATH="${INSTALLED_APP_PATH:A}"

INSTALLED_INFO_PLIST="$INSTALLED_APP_PATH/Contents/Info.plist"
INSTALLED_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INSTALLED_INFO_PLIST")"
INSTALLED_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INSTALLED_INFO_PLIST")"
INSTALLED_EXECUTABLE_PATH="$INSTALLED_APP_PATH/Contents/MacOS/$INSTALLED_EXECUTABLE"
INSTALLED_WHISPER_CLI_PATH="$INSTALLED_APP_PATH/Contents/Resources/whisper/bin/whisper-cli"
INSTALLED_WHISPER_MODEL_PATH="$INSTALLED_APP_PATH/Contents/Resources/whisper/models/ggml-tiny.bin"

if [[ "$INSTALLED_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
  echo "Unexpected bundle identifier: expected $EXPECTED_BUNDLE_ID but found $INSTALLED_BUNDLE_ID" >&2
  exit 1
fi
if [[ "$INSTALLED_EXECUTABLE" != "$EXPECTED_EXECUTABLE" ]]; then
  echo "Unexpected executable: expected $EXPECTED_EXECUTABLE but found $INSTALLED_EXECUTABLE" >&2
  exit 1
fi
if [[ ! -x "$INSTALLED_EXECUTABLE_PATH" ]]; then
  echo "Missing executable at $INSTALLED_EXECUTABLE_PATH" >&2
  exit 1
fi
if [[ ! -x "$INSTALLED_WHISPER_CLI_PATH" ]]; then
  echo "Missing bundled whisper-cli at $INSTALLED_WHISPER_CLI_PATH" >&2
  exit 1
fi
if [[ ! -f "$INSTALLED_WHISPER_MODEL_PATH" ]]; then
  echo "Missing bundled whisper model at $INSTALLED_WHISPER_MODEL_PATH" >&2
  exit 1
fi
if ! codesign --verify --deep --strict "$INSTALLED_APP_PATH"; then
  echo "Extracted release application failed code-signature verification: $INSTALLED_APP_PATH" >&2
  exit 1
fi
INSTALLED_AUDIO_INPUT_ENTITLEMENT="$(
  codesign -d --entitlements :- "$INSTALLED_APP_PATH" 2>/dev/null \
    | /usr/bin/plutil -extract 'com\.apple\.security\.device\.audio-input' raw -o - - 2>/dev/null \
    || true
)"
if [[ "$INSTALLED_AUDIO_INPUT_ENTITLEMENT" != "true" ]]; then
  echo "Extracted release application is missing com.apple.security.device.audio-input=true." >&2
  exit 1
fi
EXPECTED_MODEL_SHA256="$(awk 'NF { print $1; exit }' "$ROOT_DIR/app/macos/PushWrite/Assets/whisper-model.sha256")"
INSTALLED_MODEL_SHA256="$(shasum -a 256 "$INSTALLED_WHISPER_MODEL_PATH" | awk '{print $1}')"
if [[ -z "$EXPECTED_MODEL_SHA256" || "$INSTALLED_MODEL_SHA256" != "$EXPECTED_MODEL_SHA256" ]]; then
  echo "Bundled whisper model checksum mismatch in extracted release application." >&2
  exit 1
fi

LS_RUNTIME_DIR="$RUNTIME_ROOT/ls-probe"
LS_RESULTS_FILE="$RUNTIME_ROOT/ls-probe-summary.json"
LS_STDOUT_FILE="$RUNTIME_ROOT/ls-probe-stdout.txt"
LS_STDERR_FILE="$RUNTIME_ROOT/ls-probe-stderr.txt"

set +e
"$HOTKEY_VALIDATION_SCRIPT" \
  --product-app-path "$INSTALLED_APP_PATH" \
  --skip-build \
  --skip-blocked-validation \
  --textedit-runs 0 \
  --safari-runs 0 \
  --success-runtime-dir "$LS_RUNTIME_DIR" \
  --results-file "$LS_RESULTS_FILE" >"$LS_STDOUT_FILE" 2>"$LS_STDERR_FILE"
LS_EXIT_CODE=$?
set -e

LS_STATE_FILE="$LS_RUNTIME_DIR/product-state.json"
if [[ ! -f "$LS_STATE_FILE" ]]; then
  echo "LaunchServices probe did not produce product-state.json at $LS_STATE_FILE" >&2
  echo "hotkey-validation stderr:" >&2
  cat "$LS_STDERR_FILE" >&2
  exit 1
fi

LS_STATE_BUNDLE_ID="$(read_json_raw bundleID "$LS_STATE_FILE")"
LS_STATE_APP_PATH="$(read_json_raw appPath "$LS_STATE_FILE")"
if [[ "$LS_STATE_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
  echo "LaunchServices probe bundle mismatch: expected $EXPECTED_BUNDLE_ID but found $LS_STATE_BUNDLE_ID" >&2
  exit 1
fi

SUCCESS_RUNTIME_DIR="$RUNTIME_ROOT/success"
SUCCESS_RESPONSE_FILE="$RUNTIME_ROOT/validation-success-summary.json"
SUCCESS_STDOUT_FILE="$RUNTIME_ROOT/validation-success-stdout.txt"
SUCCESS_STDERR_FILE="$RUNTIME_ROOT/validation-success-stderr.txt"

set +e
"$TRANSCRIPTION_VALIDATION_SCRIPT" \
  --scenario success \
  --skip-build \
  --product-app-path "$INSTALLED_APP_PATH" \
  --success-runtime-dir "$SUCCESS_RUNTIME_DIR" \
  --whisper-cli-path "$INSTALLED_WHISPER_CLI_PATH" \
  --whisper-model-path "$INSTALLED_WHISPER_MODEL_PATH" \
  --results-file "$SUCCESS_RESPONSE_FILE" >"$SUCCESS_STDOUT_FILE" 2>"$SUCCESS_STDERR_FILE"
SUCCESS_EXIT_CODE=$?
set -e

if [[ "$SUCCESS_EXIT_CODE" -ne 0 || ! -f "$SUCCESS_RESPONSE_FILE" ]]; then
  echo "Success validation failed for the extracted release application." >&2
  cat "$SUCCESS_STDERR_FILE" >&2
  exit 1
fi

SUCCESS_SCENARIO_PASSED="$(read_json_raw success "$SUCCESS_RESPONSE_FILE")"
SUCCESS_STATUS="$(read_json_raw hotKeyResponse.status "$SUCCESS_RESPONSE_FILE")"
SUCCESS_INSERT_ROUTE="$(read_json_raw hotKeyResponse.insertRoute "$SUCCESS_RESPONSE_FILE")"
SUCCESS_INSERT_SOURCE="$(read_json_raw hotKeyResponse.insertSource "$SUCCESS_RESPONSE_FILE")"
SUCCESS_SYNTHETIC_PASTE_POSTED="$(read_json_raw hotKeyResponse.syntheticPastePosted "$SUCCESS_RESPONSE_FILE")"
SUCCESS_CLIPBOARD_RESTORED="$(read_json_raw hotKeyResponse.clipboardRestored "$SUCCESS_RESPONSE_FILE")"
SUCCESS_OBSERVED_TEXT="$(read_json_raw observedText "$SUCCESS_RESPONSE_FILE")"
SUCCESS_TRANSCRIPTION_TEXT="$(read_json_raw hotKeyResponse.transcriptionArtifact.text "$SUCCESS_RESPONSE_FILE")"

if [[ "$SUCCESS_SCENARIO_PASSED" != "true" ]]; then
  echo "Success validation failed: the end-to-end scenario reported failure." >&2
  exit 1
fi
if [[ "$SUCCESS_STATUS" != "succeeded" ]]; then
  echo "Success validation failed: expected status=succeeded but got '$SUCCESS_STATUS'" >&2
  exit 1
fi
if [[ "$SUCCESS_INSERT_ROUTE" != "accessibilitySelectedText" && "$SUCCESS_INSERT_ROUTE" != "accessibilityValueReplacement" && "$SUCCESS_INSERT_ROUTE" != "unicodeKeyboardEvents" && "$SUCCESS_INSERT_ROUTE" != "opaqueUnicodeKeyboardEvents" ]]; then
  echo "Success validation failed: expected a pasteboard-free insert route but got '$SUCCESS_INSERT_ROUTE'" >&2
  exit 1
fi
if [[ "$SUCCESS_INSERT_SOURCE" != "transcription" ]]; then
  echo "Success validation failed: expected insertSource=transcription but got '$SUCCESS_INSERT_SOURCE'" >&2
  exit 1
fi
if [[ "$SUCCESS_SYNTHETIC_PASTE_POSTED" != "false" ]]; then
  echo "Success validation failed: expected syntheticPastePosted=false but got '$SUCCESS_SYNTHETIC_PASTE_POSTED'" >&2
  exit 1
fi
if [[ "$SUCCESS_CLIPBOARD_RESTORED" != "true" ]]; then
  echo "Success validation failed: expected clipboardRestored=true but got '$SUCCESS_CLIPBOARD_RESTORED'" >&2
  exit 1
fi
if [[ -z "$SUCCESS_TRANSCRIPTION_TEXT" || "$SUCCESS_OBSERVED_TEXT" != "$SUCCESS_TRANSCRIPTION_TEXT" ]]; then
  echo "Success validation failed: TextEdit content does not match the inserted transcription." >&2
  exit 1
fi

BLOCKED_RUNTIME_DIR="$RUNTIME_ROOT/blocked"
BLOCKED_RESPONSE_FILE="$BLOCKED_RUNTIME_DIR/validation-blocked-response.json"

"$CONTROL_SCRIPT" \
  launch \
  --force-accessibility-blocked \
  --product-app "$INSTALLED_APP_PATH" \
  --runtime-dir "$BLOCKED_RUNTIME_DIR" >/dev/null

wait_for_file "$BLOCKED_RUNTIME_DIR/product-state.json" 20

"$CONTROL_SCRIPT" \
  preflight \
  --timeout-ms 15000 \
  --product-app "$INSTALLED_APP_PATH" \
  --runtime-dir "$BLOCKED_RUNTIME_DIR" > "$BLOCKED_RESPONSE_FILE"

BLOCKED_STATUS="$(read_json_raw status "$BLOCKED_RESPONSE_FILE")"
BLOCKED_REASON="$(read_json_raw blockedReason "$BLOCKED_RESPONSE_FILE")"
BLOCKED_ACCESSIBILITY_TRUSTED="$(read_json_raw accessibilityTrusted "$BLOCKED_RESPONSE_FILE")"

if [[ "$BLOCKED_STATUS" != "blocked" ]]; then
  echo "Negative validation failed: expected status=blocked but got '$BLOCKED_STATUS'" >&2
  exit 1
fi
if [[ "$BLOCKED_ACCESSIBILITY_TRUSTED" != "false" || -z "$BLOCKED_REASON" ]]; then
  echo "Negative validation failed: expected an untrusted accessibility state and a user-facing reason." >&2
  exit 1
fi

"$CONTROL_SCRIPT" stop --timeout-ms 5000 --product-app "$INSTALLED_APP_PATH" --runtime-dir "$BLOCKED_RUNTIME_DIR" >/dev/null || true

if [[ -n "$RESULTS_FILE" ]]; then
  RESULTS_FILE="${RESULTS_FILE:A}"
  mkdir -p "$(dirname "$RESULTS_FILE")"
  cat > "$RESULTS_FILE" <<RESULTS
validated_at_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
artifact_zip=$ARTIFACT_ZIP
install_root=$INSTALL_ROOT
installed_app_path=$INSTALLED_APP_PATH
bundle_identifier=$INSTALLED_BUNDLE_ID
bundle_executable=$INSTALLED_EXECUTABLE
bundled_whisper_cli_path=$INSTALLED_WHISPER_CLI_PATH
bundled_whisper_model_path=$INSTALLED_WHISPER_MODEL_PATH
primary_start_path=LaunchServicesAPI-NSWorkspace-openApplication-via-run_pushwrite_hotkey_validation
launchservices_probe_exit_code=$LS_EXIT_CODE
launchservices_probe_state_file=$LS_STATE_FILE
launchservices_probe_bundle_id=$LS_STATE_BUNDLE_ID
launchservices_probe_app_path=$LS_STATE_APP_PATH
launchservices_probe_stdout=$LS_STDOUT_FILE
launchservices_probe_stderr=$LS_STDERR_FILE
launchservices_probe_results=$LS_RESULTS_FILE
success_runtime_dir=$SUCCESS_RUNTIME_DIR
success_response_file=$SUCCESS_RESPONSE_FILE
success_exit_code=$SUCCESS_EXIT_CODE
success_status=$SUCCESS_STATUS
success_insert_route=$SUCCESS_INSERT_ROUTE
success_insert_source=$SUCCESS_INSERT_SOURCE
success_synthetic_paste_posted=$SUCCESS_SYNTHETIC_PASTE_POSTED
success_clipboard_restored=$SUCCESS_CLIPBOARD_RESTORED
success_observed_text_matches=true
negative_runtime_dir=$BLOCKED_RUNTIME_DIR
negative_response_file=$BLOCKED_RESPONSE_FILE
negative_status=$BLOCKED_STATUS
negative_accessibility_trusted=$BLOCKED_ACCESSIBILITY_TRUSTED
negative_blocked_reason=$BLOCKED_REASON
RESULTS
fi

printf '%s\n' "artifact_zip=$ARTIFACT_ZIP"
printf '%s\n' "install_root=$INSTALL_ROOT"
printf '%s\n' "installed_app_path=$INSTALLED_APP_PATH"
printf '%s\n' "bundle_identifier=$INSTALLED_BUNDLE_ID"
printf '%s\n' "bundle_executable=$INSTALLED_EXECUTABLE"
printf '%s\n' "bundled_whisper_cli_path=$INSTALLED_WHISPER_CLI_PATH"
printf '%s\n' "bundled_whisper_model_path=$INSTALLED_WHISPER_MODEL_PATH"
printf '%s\n' "primary_start_path=LaunchServicesAPI-NSWorkspace-openApplication-via-run_pushwrite_hotkey_validation"
printf '%s\n' "launchservices_probe_exit_code=$LS_EXIT_CODE"
printf '%s\n' "launchservices_probe_state_file=$LS_STATE_FILE"
printf '%s\n' "success_runtime_dir=$SUCCESS_RUNTIME_DIR"
printf '%s\n' "success_response_file=$SUCCESS_RESPONSE_FILE"
printf '%s\n' "success_exit_code=$SUCCESS_EXIT_CODE"
printf '%s\n' "success_status=$SUCCESS_STATUS"
printf '%s\n' "success_insert_route=$SUCCESS_INSERT_ROUTE"
printf '%s\n' "success_synthetic_paste_posted=$SUCCESS_SYNTHETIC_PASTE_POSTED"
printf '%s\n' "success_clipboard_restored=$SUCCESS_CLIPBOARD_RESTORED"
printf '%s\n' "success_observed_text_matches=true"
printf '%s\n' "negative_runtime_dir=$BLOCKED_RUNTIME_DIR"
printf '%s\n' "negative_response_file=$BLOCKED_RESPONSE_FILE"
printf '%s\n' "negative_status=$BLOCKED_STATUS"
printf '%s\n' "negative_accessibility_trusted=$BLOCKED_ACCESSIBILITY_TRUSTED"
