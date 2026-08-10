#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/app/macos/PushWrite/Info.plist"

usage() {
  cat <<USAGE
Usage: scripts/validate_pushwrite_release_candidate_install.sh [options]

Options:
  --artifact-zip <path>       Path to release ZIP artifact (required)
  --expected-sha256 <digest>  Expected SHA-256 for the ZIP (required)
  --install-root <path>       New, empty scratch root under /tmp or <repo>/build
  --runtime-root <path>       New, empty scratch root under /tmp or <repo>/build
  --results-file <path>       Optional summary output file
  -h, --help                  Show this help
USAGE
}

ARTIFACT_ZIP=""
EXPECTED_SHA256=""
INSTALL_ROOT=""
RUNTIME_ROOT=""
RESULTS_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-zip)
      [[ $# -ge 2 ]] || { echo "Missing value for --artifact-zip." >&2; exit 64; }
      ARTIFACT_ZIP="$2"
      shift 2
      ;;
    --expected-sha256)
      [[ $# -ge 2 ]] || { echo "Missing value for --expected-sha256." >&2; exit 64; }
      EXPECTED_SHA256="${2:l}"
      shift 2
      ;;
    --install-root)
      [[ $# -ge 2 ]] || { echo "Missing value for --install-root." >&2; exit 64; }
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --runtime-root)
      [[ $# -ge 2 ]] || { echo "Missing value for --runtime-root." >&2; exit 64; }
      RUNTIME_ROOT="$2"
      shift 2
      ;;
    --results-file)
      [[ $# -ge 2 ]] || { echo "Missing value for --results-file." >&2; exit 64; }
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

if [[ -z "$ARTIFACT_ZIP" || -z "$EXPECTED_SHA256" ]]; then
  echo "Both --artifact-zip and --expected-sha256 are required." >&2
  usage >&2
  exit 64
fi
if ! printf '%s' "$EXPECTED_SHA256" | /usr/bin/grep -Eq '^[0-9a-f]{64}$'; then
  echo "Expected SHA-256 must be exactly 64 lowercase hexadecimal characters." >&2
  exit 64
fi

ARTIFACT_ZIP="${ARTIFACT_ZIP:A}"
if [[ ! -f "$ARTIFACT_ZIP" || -L "$ARTIFACT_ZIP" ]]; then
  echo "Release artifact must be a regular, non-symlink file: $ARTIFACT_ZIP" >&2
  exit 1
fi

# Authenticate the exact archive before parsing or extracting any of its content.
ACTUAL_SHA256="$(shasum -a 256 "$ARTIFACT_ZIP" | awk '{print $1}')"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "Release artifact SHA-256 mismatch." >&2
  echo "Expected: $EXPECTED_SHA256" >&2
  echo "Actual:   $ACTUAL_SHA256" >&2
  exit 1
fi

validate_scratch_parent() {
  local candidate="${1:A}"
  local label="$2"
  case "$candidate" in
    /tmp/*|/private/tmp/*|"${ROOT_DIR:A}"/build/*)
      ;;
    *)
      echo "$label must be below /tmp or ${ROOT_DIR:A}/build: $candidate" >&2
      exit 64
      ;;
  esac
}

prepare_scratch_root() {
  local requested="$1"
  local prefix="$2"
  local resolved
  if [[ -z "$requested" ]]; then
    mktemp -d "/tmp/${prefix}.XXXXXXXX"
    return
  fi
  validate_scratch_parent "$requested" "$prefix"
  if [[ -e "$requested" || -L "$requested" ]]; then
    echo "$prefix must not already exist: $requested" >&2
    exit 64
  fi
  mkdir -m 700 -p "$requested"
  resolved="${requested:A}"
  printf '%s\n' "$resolved"
}

INSTALL_ROOT="$(prepare_scratch_root "$INSTALL_ROOT" "pushwrite-install")"
RUNTIME_ROOT="$(prepare_scratch_root "$RUNTIME_ROOT" "pushwrite-runtime")"
if [[ "$INSTALL_ROOT" == "$RUNTIME_ROOT" ]]; then
  echo "Install root and runtime root must differ." >&2
  exit 64
fi

ARCHIVE_LIST="$RUNTIME_ROOT/archive-list.txt"
/usr/bin/zipinfo -1 "$ARTIFACT_ZIP" > "$ARCHIVE_LIST"
if [[ ! -s "$ARCHIVE_LIST" ]]; then
  echo "Release artifact contains no files." >&2
  exit 1
fi
if /usr/bin/awk '
  /^\// { bad=1 }
  { n=split($0,p,"/"); for (i=1;i<=n;i++) if (p[i]=="..") bad=1 }
  END { exit bad ? 0 : 1 }
' "$ARCHIVE_LIST"; then
  echo "Release artifact contains an unsafe absolute or parent-traversal path." >&2
  exit 1
fi

/usr/bin/ditto -x -k "$ARTIFACT_ZIP" "$INSTALL_ROOT"
if /usr/bin/find "$INSTALL_ROOT" -type l -print -quit | /usr/bin/grep -q .; then
  echo "Extracted release contains an unexpected symbolic link." >&2
  exit 1
fi

APP_PATHS=("$INSTALL_ROOT"/*.app(N/))
if [[ ${#APP_PATHS[@]} -ne 1 ]]; then
  echo "Expected exactly one top-level .app bundle after extraction." >&2
  exit 1
fi
INSTALLED_APP_PATH="${APP_PATHS[1]:A}"
INSTALLED_INFO_PLIST="$INSTALLED_APP_PATH/Contents/Info.plist"
EXPECTED_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
EXPECTED_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"
EXPECTED_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
INSTALLED_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INSTALLED_INFO_PLIST")"
INSTALLED_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INSTALLED_INFO_PLIST")"
INSTALLED_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INSTALLED_INFO_PLIST")"
INSTALLED_EXECUTABLE_PATH="$INSTALLED_APP_PATH/Contents/MacOS/$INSTALLED_EXECUTABLE"
INSTALLED_WHISPER_CLI_PATH="$INSTALLED_APP_PATH/Contents/Resources/whisper/bin/whisper-cli"
INSTALLED_WHISPER_MODEL_PATH="$INSTALLED_APP_PATH/Contents/Resources/whisper/models/ggml-large-v3-q5_0.bin"
INSTALLED_LOCAL_TEXT_CLI_PATH="$INSTALLED_APP_PATH/Contents/Resources/local-text/bin/llama-completion"
INSTALLED_LOCAL_TEXT_MODEL_PATH="$INSTALLED_APP_PATH/Contents/Resources/local-text/models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
INSTALLED_APP_ICON_PATH="$INSTALLED_APP_PATH/Contents/Resources/PushWrite.icns"

if [[ "$INSTALLED_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ||
      "$INSTALLED_EXECUTABLE" != "$EXPECTED_EXECUTABLE" ||
      "$INSTALLED_VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "Extracted application identity does not match the release source." >&2
  exit 1
fi
for executable in "$INSTALLED_EXECUTABLE_PATH" "$INSTALLED_WHISPER_CLI_PATH" "$INSTALLED_LOCAL_TEXT_CLI_PATH"; do
  if [[ ! -x "$executable" ]]; then
    echo "Missing executable: $executable" >&2
    exit 1
  fi
done
for payload in \
  "$INSTALLED_WHISPER_MODEL_PATH" \
  "$INSTALLED_LOCAL_TEXT_MODEL_PATH" \
  "$INSTALLED_APP_ICON_PATH" \
  "$INSTALLED_APP_PATH/Contents/Resources/whisper/licenses/whisper.cpp-LICENSE.txt" \
  "$INSTALLED_APP_PATH/Contents/Resources/whisper/licenses/OpenAI-Whisper-LICENSE.txt" \
  "$INSTALLED_APP_PATH/Contents/Resources/local-text/licenses/Qwen2.5-LICENSE.txt" \
  "$INSTALLED_APP_PATH/Contents/Resources/local-text/licenses/llama.cpp-LICENSE.txt" \
  "$INSTALLED_APP_PATH/Contents/Resources/THIRD_PARTY_NOTICES.md"; do
  if [[ ! -f "$payload" ]]; then
    echo "Missing bundled payload: $payload" >&2
    exit 1
  fi
done

/usr/bin/codesign --verify --deep --strict "$INSTALLED_APP_PATH"
SIGNATURE_DETAILS="$(/usr/bin/codesign -dvv "$INSTALLED_APP_PATH" 2>&1)"
if printf '%s\n' "$SIGNATURE_DETAILS" | /usr/bin/grep -F 'Signature=adhoc' >/dev/null; then
  INSTALLED_SIGNATURE_MODE="ad-hoc"
else
  INSTALLED_SIGNATURE_MODE="developer-id"
fi
INSTALLED_TEAM_ID="$(printf '%s\n' "$SIGNATURE_DETAILS" | awk -F= '/^TeamIdentifier=/{print $2; exit}')"
if [[ -n "${PUSHWRITE_EXPECTED_TEAM_ID:-}" ]]; then
  if [[ "$INSTALLED_TEAM_ID" != "$PUSHWRITE_EXPECTED_TEAM_ID" ]]; then
    echo "Extracted application TeamIdentifier does not match the stable release identity." >&2
    exit 1
  fi
  /usr/bin/xcrun stapler validate "$INSTALLED_APP_PATH"
  /usr/bin/spctl --assess --type execute --verbose=4 "$INSTALLED_APP_PATH"
fi
ENTITLEMENTS_FILE="$RUNTIME_ROOT/entitlements.plist"
/usr/bin/codesign -d --entitlements :- "$INSTALLED_APP_PATH" >"$ENTITLEMENTS_FILE" 2>/dev/null
if ! /usr/bin/python3 - "$ENTITLEMENTS_FILE" <<'PY'
import plistlib
import sys

with open(sys.argv[1], "rb") as handle:
    entitlements = plistlib.load(handle)
expected = {"com.apple.security.device.audio-input": True}
raise SystemExit(0 if entitlements == expected else 1)
PY
then
  echo "Extracted application entitlements do not match the exact release allowlist." >&2
  exit 1
fi

EXPECTED_WHISPER_SHA256="$(awk 'NF {print $1; exit}' "$ROOT_DIR/app/macos/PushWrite/Assets/whisper-model.sha256")"
EXPECTED_LOCAL_TEXT_SHA256="$(awk 'NF {print $1; exit}' "$ROOT_DIR/app/macos/PushWrite/Assets/local-text-model.sha256")"
EXPECTED_APP_ICON_SHA256="$(awk 'NF {print $1; exit}' "$ROOT_DIR/app/macos/PushWrite/Assets/PushWrite.icns.sha256")"
if [[ "$(shasum -a 256 "$INSTALLED_WHISPER_MODEL_PATH" | awk '{print $1}')" != "$EXPECTED_WHISPER_SHA256" ||
      "$(shasum -a 256 "$INSTALLED_LOCAL_TEXT_MODEL_PATH" | awk '{print $1}')" != "$EXPECTED_LOCAL_TEXT_SHA256" ]]; then
  echo "A bundled model failed its release checksum check." >&2
  exit 1
fi
if [[ "$(shasum -a 256 "$INSTALLED_APP_ICON_PATH" | awk '{print $1}')" != "$EXPECTED_APP_ICON_SHA256" ]]; then
  echo "Installed application does not contain the approved PushWrite app icon." >&2
  exit 1
fi
if /usr/bin/otool -L "$INSTALLED_LOCAL_TEXT_CLI_PATH" | /usr/bin/grep -Eq '(libcurl|libssl|libcrypto)'; then
  echo "Bundled local text runtime unexpectedly links a network or TLS library." >&2
  exit 1
fi

if /usr/bin/strings "$INSTALLED_EXECUTABLE_PATH" | /usr/bin/grep -F 'PUSHWRITE_' >/dev/null; then
  echo "Production executable contains a QA or runtime override marker." >&2
  exit 1
fi

BEFORE_PIDS=("${(@f)$(/usr/bin/pgrep -x "$INSTALLED_EXECUTABLE" 2>/dev/null || true)}")
/usr/bin/open -n "$INSTALLED_APP_PATH"
LAUNCHED_PID=""
for _ in {1..100}; do
  CURRENT_PIDS=("${(@f)$(/usr/bin/pgrep -x "$INSTALLED_EXECUTABLE" 2>/dev/null || true)}")
  for candidate in "${CURRENT_PIDS[@]}"; do
    [[ -n "$candidate" ]] || continue
    if (( ${BEFORE_PIDS[(Ie)$candidate]} == 0 )); then
      LAUNCHED_PID="$candidate"
      break
    fi
  done
  [[ -n "$LAUNCHED_PID" ]] && break
  sleep 0.1
done
if [[ -z "$LAUNCHED_PID" ]]; then
  echo "LaunchServices did not start the extracted application within 10 seconds." >&2
  exit 1
fi
/bin/kill -TERM "$LAUNCHED_PID" 2>/dev/null || true

if [[ -n "$RESULTS_FILE" ]]; then
  RESULTS_FILE="${RESULTS_FILE:A}"
  mkdir -p "${RESULTS_FILE:h}"
  cat > "$RESULTS_FILE" <<RESULTS
validated_at_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
artifact_zip=$ARTIFACT_ZIP
artifact_sha256=$ACTUAL_SHA256
install_root=$INSTALL_ROOT
runtime_root=$RUNTIME_ROOT
installed_app_path=$INSTALLED_APP_PATH
bundle_identifier=$INSTALLED_BUNDLE_ID
bundle_version=$INSTALLED_VERSION
signature_mode=$INSTALLED_SIGNATURE_MODE
team_identifier=$INSTALLED_TEAM_ID
entitlements_exact=true
bundled_models_verified=true
app_icon_verified=true
runtime_dependencies_verified=true
production_qa_markers_absent=true
launchservices_smoke_passed=true
RESULTS
fi

printf '%s\n' "artifact_zip=$ARTIFACT_ZIP"
printf '%s\n' "artifact_sha256=$ACTUAL_SHA256"
printf '%s\n' "installed_app_path=$INSTALLED_APP_PATH"
printf '%s\n' "bundle_identifier=$INSTALLED_BUNDLE_ID"
printf '%s\n' "bundle_version=$INSTALLED_VERSION"
printf '%s\n' "signature_mode=$INSTALLED_SIGNATURE_MODE"
printf '%s\n' "team_identifier=$INSTALLED_TEAM_ID"
printf '%s\n' "entitlements_exact=true"
printf '%s\n' "bundled_models_verified=true"
printf '%s\n' "app_icon_verified=true"
printf '%s\n' "runtime_dependencies_verified=true"
printf '%s\n' "production_qa_markers_absent=true"
printf '%s\n' "launchservices_smoke_passed=true"
