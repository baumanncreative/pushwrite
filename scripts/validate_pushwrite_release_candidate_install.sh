#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTROL_SCRIPT="$ROOT_DIR/scripts/control_pushwrite_product.sh"
HOTKEY_VALIDATION_SCRIPT="$ROOT_DIR/scripts/run_pushwrite_hotkey_validation.sh"
INFO_PLIST="$ROOT_DIR/app/macos/PushWrite/Info.plist"

usage() {
  cat <<USAGE
Usage: scripts/validate_pushwrite_release_candidate_install.sh [options]

Options:
  --artifact-zip <path>     Path to release zip artifact (required)
  --install-root <path>     Install extraction root (default: /tmp/pushwrite-rc-install)
  --runtime-root <path>     Runtime/log root (default: /tmp/pushwrite-rc-validation)
  --success-text <text>     Text used for success insert check
  --results-file <path>     Optional summary output file
  -h, --help                Show this help
USAGE
}

ARTIFACT_ZIP=""
INSTALL_ROOT="/tmp/pushwrite-rc-install"
RUNTIME_ROOT="/tmp/pushwrite-rc-validation"
SUCCESS_TEXT="PushWrite 008 RC install validation success."
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
    --success-text)
      SUCCESS_TEXT="$2"
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
SUCCESS_RESPONSE_FILE="$SUCCESS_RUNTIME_DIR/validation-success-response.json"

"$CONTROL_SCRIPT" \
  launch \
  --force-accessibility-trusted \
  --force-microphone-permission-status granted \
  --force-microphone-request-result granted \
  --product-app "$INSTALLED_APP_PATH" \
  --runtime-dir "$SUCCESS_RUNTIME_DIR" >/dev/null

wait_for_file "$SUCCESS_RUNTIME_DIR/product-state.json" 20

"$CONTROL_SCRIPT" \
  insert-transcription \
  --text "$SUCCESS_TEXT" \
  --timeout-ms 20000 \
  --product-app "$INSTALLED_APP_PATH" \
  --runtime-dir "$SUCCESS_RUNTIME_DIR" > "$SUCCESS_RESPONSE_FILE"

SUCCESS_STATUS="$(read_json_raw status "$SUCCESS_RESPONSE_FILE")"
SUCCESS_INSERT_ROUTE="$(read_json_raw insertRoute "$SUCCESS_RESPONSE_FILE")"
SUCCESS_INSERT_SOURCE="$(read_json_raw insertSource "$SUCCESS_RESPONSE_FILE")"
SUCCESS_SYNTHETIC_PASTE_POSTED="$(read_json_raw syntheticPastePosted "$SUCCESS_RESPONSE_FILE")"

if [[ "$SUCCESS_STATUS" != "succeeded" ]]; then
  echo "Success validation failed: expected status=succeeded but got '$SUCCESS_STATUS'" >&2
  exit 1
fi
if [[ "$SUCCESS_INSERT_ROUTE" != "pasteboardCommandV" ]]; then
  echo "Success validation failed: expected insertRoute=pasteboardCommandV but got '$SUCCESS_INSERT_ROUTE'" >&2
  exit 1
fi
if [[ "$SUCCESS_INSERT_SOURCE" != "transcription" ]]; then
  echo "Success validation failed: expected insertSource=transcription but got '$SUCCESS_INSERT_SOURCE'" >&2
  exit 1
fi
if [[ "$SUCCESS_SYNTHETIC_PASTE_POSTED" != "true" ]]; then
  echo "Success validation failed: expected syntheticPastePosted=true but got '$SUCCESS_SYNTHETIC_PASTE_POSTED'" >&2
  exit 1
fi

"$CONTROL_SCRIPT" stop --timeout-ms 5000 --product-app "$INSTALLED_APP_PATH" --runtime-dir "$SUCCESS_RUNTIME_DIR" >/dev/null || true

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

if [[ "$BLOCKED_STATUS" != "blocked" ]]; then
  echo "Negative validation failed: expected status=blocked but got '$BLOCKED_STATUS'" >&2
  exit 1
fi
if [[ "$BLOCKED_REASON" != *"Accessibility access is required"* ]]; then
  echo "Negative validation failed: blockedReason does not contain expected accessibility message." >&2
  echo "blockedReason=$BLOCKED_REASON" >&2
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
success_status=$SUCCESS_STATUS
success_insert_route=$SUCCESS_INSERT_ROUTE
success_insert_source=$SUCCESS_INSERT_SOURCE
success_synthetic_paste_posted=$SUCCESS_SYNTHETIC_PASTE_POSTED
negative_runtime_dir=$BLOCKED_RUNTIME_DIR
negative_response_file=$BLOCKED_RESPONSE_FILE
negative_status=$BLOCKED_STATUS
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
printf '%s\n' "success_status=$SUCCESS_STATUS"
printf '%s\n' "success_insert_route=$SUCCESS_INSERT_ROUTE"
printf '%s\n' "success_synthetic_paste_posted=$SUCCESS_SYNTHETIC_PASTE_POSTED"
printf '%s\n' "negative_runtime_dir=$BLOCKED_RUNTIME_DIR"
printf '%s\n' "negative_response_file=$BLOCKED_RESPONSE_FILE"
printf '%s\n' "negative_status=$BLOCKED_STATUS"
