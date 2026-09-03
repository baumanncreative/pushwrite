#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_APP_PATH="$ROOT_DIR/build/pushwrite-0.3.2-qa/PushWrite.app"
RESULTS_FILE="$ROOT_DIR/build/pushwrite-0.3.2-qa/instance-validation.txt"
TEST_ROOT=""
typeset -a TEST_PIDS=()

usage() {
  cat <<USAGE
Usage: scripts/run_pushwrite_instance_validation.sh [options]

Validates the macOS single-instance and upgrade-conflict behaviour.

Options:
  --product-app-path <path>  QA app bundle to validate
  --results-file <path>      Text result path
  -h, --help                 Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --product-app-path)
      PRODUCT_APP_PATH="$2"
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

PRODUCT_APP_PATH="${PRODUCT_APP_PATH:A}"
RESULTS_FILE="${RESULTS_FILE:A}"
PRODUCT_EXECUTABLE="$PRODUCT_APP_PATH/Contents/MacOS/PushWrite"

if [[ ! -x "$PRODUCT_EXECUTABLE" ]]; then
  echo "Missing QA executable at $PRODUCT_EXECUTABLE" >&2
  exit 1
fi
if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PRODUCT_APP_PATH/Contents/Info.plist")" != "ch.baumanncreative.pushwrite.qa" ]]; then
  echo "Instance validation requires the QA bundle identifier." >&2
  exit 1
fi

TEST_ROOT="$(mktemp -d /private/tmp/pushwrite-instance-validation.XXXXXXXX)"

cleanup() {
  local pid
  for pid in "${TEST_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
    fi
  done
  for pid in "${TEST_PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
  case "$TEST_ROOT" in
    /private/tmp/pushwrite-instance-validation.*)
      /bin/rm -rf -- "$TEST_ROOT"
      ;;
  esac
}
trap cleanup EXIT INT TERM

fail() {
  echo "instance_validation_failed: $1" >&2
  exit 1
}

is_alive() {
  kill -0 "$1" 2>/dev/null
}

wait_for_file() {
  local target_file="$1"
  local attempts="${2:-120}"
  local index=0
  while (( index < attempts )); do
    [[ -f "$target_file" ]] && return 0
    sleep 0.1
    (( index += 1 ))
  done
  return 1
}

wait_for_exit() {
  local pid="$1"
  local attempts="${2:-60}"
  local index=0
  while (( index < attempts )); do
    is_alive "$pid" || return 0
    sleep 0.1
    (( index += 1 ))
  done
  return 1
}

launch_product() {
  local app_path="$1"
  local runtime_path="$2"
  local log_prefix="$3"
  PUSHWRITE_ENABLE_CONTROL_INTERFACE=1 \
    "$app_path/Contents/MacOS/PushWrite" \
    --runtime-dir "$runtime_path" \
    --force-accessibility-trusted \
    >"$log_prefix.out" 2>"$log_prefix.err" &
  LAUNCHED_PID=$!
  TEST_PIDS+=("$LAUNCHED_PID")
}

stop_pid() {
  local pid="$1"
  if is_alive "$pid"; then
    kill -TERM "$pid"
    wait_for_exit "$pid" 40 || fail "process $pid did not terminate"
  fi
}

mkdir -p "${RESULTS_FILE:h}"
: > "$RESULTS_FILE"

# 1. A second launch from the same bundle must activate the owner and exit.
same_root="$TEST_ROOT/same-path"
mkdir -p "$same_root"
launch_product "$PRODUCT_APP_PATH" "$same_root/runtime-owner" "$same_root/owner"
same_owner_pid="$LAUNCHED_PID"
wait_for_file "$same_root/runtime-owner/product-state.json" || fail "owner did not create product state"
launch_product "$PRODUCT_APP_PATH" "$same_root/runtime-contender" "$same_root/contender"
same_contender_pid="$LAUNCHED_PID"
wait_for_exit "$same_contender_pid" || fail "same-path contender did not exit"
is_alive "$same_owner_pid" || fail "same-path owner exited unexpectedly"
[[ ! -e "$same_root/runtime-contender" ]] || fail "same-path contender touched runtime data"
echo "same_path_handoff: passed" >> "$RESULTS_FILE"
stop_pid "$same_owner_pid"

# 2. A simultaneous launch must elect exactly one runtime owner.
race_root="$TEST_ROOT/race"
mkdir -p "$race_root"
launch_product "$PRODUCT_APP_PATH" "$race_root/runtime-a" "$race_root/a"
race_a_pid="$LAUNCHED_PID"
launch_product "$PRODUCT_APP_PATH" "$race_root/runtime-b" "$race_root/b"
race_b_pid="$LAUNCHED_PID"
for _ in {1..120}; do
  state_count=0
  [[ -f "$race_root/runtime-a/product-state.json" ]] && (( state_count += 1 ))
  [[ -f "$race_root/runtime-b/product-state.json" ]] && (( state_count += 1 ))
  [[ "$state_count" -eq 1 ]] && break
  sleep 0.1
done
sleep 1
race_alive_count=0
is_alive "$race_a_pid" && (( race_alive_count += 1 ))
is_alive "$race_b_pid" && (( race_alive_count += 1 ))
[[ "$state_count" -eq 1 ]] || fail "simultaneous launch created $state_count runtime owners"
[[ "$race_alive_count" -eq 1 ]] || fail "simultaneous launch left $race_alive_count active processes"
echo "simultaneous_launch_lock: passed" >> "$RESULTS_FILE"
stop_pid "$race_a_pid"
stop_pid "$race_b_pid"

# 3. A second copy at another path must be blocked before runtime preparation.
different_root="$TEST_ROOT/different-path"
mkdir -p "$different_root"
different_app="$different_root/PushWrite-copy.app"
/usr/bin/ditto "$PRODUCT_APP_PATH" "$different_app"
launch_product "$PRODUCT_APP_PATH" "$different_root/runtime-owner" "$different_root/owner"
different_owner_pid="$LAUNCHED_PID"
wait_for_file "$different_root/runtime-owner/product-state.json" || fail "different-path owner did not start"
launch_product "$different_app" "$different_root/runtime-contender" "$different_root/contender"
different_contender_pid="$LAUNCHED_PID"
sleep 2
is_alive "$different_owner_pid" || fail "different-path owner exited unexpectedly"
is_alive "$different_contender_pid" || fail "different-path contender did not remain on its conflict notice"
[[ ! -e "$different_root/runtime-contender" ]] || fail "different-path contender touched runtime data"
echo "different_path_conflict: passed" >> "$RESULTS_FILE"
stop_pid "$different_contender_pid"
stop_pid "$different_owner_pid"

# 4. A legacy process without the 0.3.2 acknowledgement protocol must block a replacement.
legacy_root="$TEST_ROOT/legacy-replacement"
legacy_slot="$legacy_root/PushWrite.app"
mkdir -p "$legacy_slot/Contents/MacOS"
cat > "$legacy_root/LegacyPushWrite.swift" <<'SWIFT'
import AppKit

let application = NSApplication.shared
application.setActivationPolicy(.accessory)
application.run()
SWIFT
swiftc -framework AppKit "$legacy_root/LegacyPushWrite.swift" -o "$legacy_slot/Contents/MacOS/PushWrite"
cat > "$legacy_slot/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>PushWrite</string>
  <key>CFBundleIdentifier</key><string>ch.baumanncreative.pushwrite.qa</string>
  <key>CFBundleName</key><string>PushWrite QA Legacy</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.3.1</string>
  <key>CFBundleVersion</key><string>301000</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
"$legacy_slot/Contents/MacOS/PushWrite" >"$legacy_root/legacy.out" 2>"$legacy_root/legacy.err" &
legacy_pid=$!
TEST_PIDS+=("$legacy_pid")
sleep 1
is_alive "$legacy_pid" || fail "legacy fixture did not start"
/bin/rm -rf -- "$legacy_slot"
/usr/bin/ditto "$PRODUCT_APP_PATH" "$legacy_slot"
launch_product "$legacy_slot" "$legacy_root/runtime-replacement" "$legacy_root/replacement"
replacement_pid="$LAUNCHED_PID"
sleep 2
is_alive "$legacy_pid" || fail "legacy fixture exited unexpectedly"
is_alive "$replacement_pid" || fail "replacement did not remain on its conflict notice"
[[ ! -e "$legacy_root/runtime-replacement" ]] || fail "replacement touched runtime data while legacy version was active"
echo "legacy_same_path_conflict: passed" >> "$RESULTS_FILE"
stop_pid "$replacement_pid"
stop_pid "$legacy_pid"

echo "final result: passed" >> "$RESULTS_FILE"
cat "$RESULTS_FILE"
