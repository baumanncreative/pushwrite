#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/scripts/control_pushwrite_product.swift"
OUTPUT_DIR="/tmp/pushwrite-product-tools"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TOOL_PATH="$OUTPUT_DIR/control_pushwrite_product"
SDK_PATH="$(xcrun --show-sdk-path)"

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE_DIR"

COMMAND="${1:-}"

if [[ "$COMMAND" == "launch" ]]; then
  PRODUCT_APP_PATH="${PUSHWRITE_PRODUCT_APP_PATH:-$ROOT_DIR/build/pushwrite-product/PushWrite.app}"
  RUNTIME_DIR="${PUSHWRITE_PRODUCT_RUNTIME_DIR:-$ROOT_DIR/build/pushwrite-product/runtime}"
  TIMEOUT_MS=10000
  SIMULATED_TEXT="${PUSHWRITE_SIMULATED_TRANSCRIPTION_TEXT:-}"
  FORCE_ACCESSIBILITY_BLOCKED=0
  FORCE_ACCESSIBILITY_TRUSTED=0
  EXECUTABLE_PATH=""
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --product-app)
        PRODUCT_APP_PATH="$2"
        shift 2
        ;;
      --runtime-dir)
        RUNTIME_DIR="$2"
        shift 2
        ;;
      --timeout-ms)
        TIMEOUT_MS="$2"
        shift 2
        ;;
      --simulated-text)
        SIMULATED_TEXT="$2"
        shift 2
        ;;
      --force-accessibility-blocked)
        FORCE_ACCESSIBILITY_BLOCKED=1
        shift 1
        ;;
      --force-accessibility-trusted)
        FORCE_ACCESSIBILITY_TRUSTED=1
        shift 1
        ;;
      *)
        echo "Unknown argument: $1" >&2
        exit 64
        ;;
    esac
  done

  if [[ ! -d "$PRODUCT_APP_PATH" ]]; then
    echo "Missing PushWrite app at $PRODUCT_APP_PATH" >&2
    exit 1
  fi
  EXECUTABLE_PATH="$PRODUCT_APP_PATH/Contents/MacOS/PushWrite"
  if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "Missing PushWrite executable at $EXECUTABLE_PATH" >&2
    exit 1
  fi

  mkdir -p "$RUNTIME_DIR"
  PUSHWRITE_LAUNCH_PRODUCT_APP_PATH="$PRODUCT_APP_PATH" \
  PUSHWRITE_LAUNCH_RUNTIME_DIR="$RUNTIME_DIR" \
  PUSHWRITE_LAUNCH_SIMULATED_TEXT="$SIMULATED_TEXT" \
  PUSHWRITE_LAUNCH_FORCE_ACCESSIBILITY_BLOCKED="$FORCE_ACCESSIBILITY_BLOCKED" \
  PUSHWRITE_LAUNCH_FORCE_ACCESSIBILITY_TRUSTED="$FORCE_ACCESSIBILITY_TRUSTED" \
  swift -e 'import AppKit; import Foundation; let env = ProcessInfo.processInfo.environment; guard let productAppPath = env["PUSHWRITE_LAUNCH_PRODUCT_APP_PATH"], let runtimeDir = env["PUSHWRITE_LAUNCH_RUNTIME_DIR"] else { fputs("Missing launch environment.\n", stderr); exit(1) }; let simulatedText = env["PUSHWRITE_LAUNCH_SIMULATED_TEXT"] ?? ""; let forceAccessibilityBlocked = env["PUSHWRITE_LAUNCH_FORCE_ACCESSIBILITY_BLOCKED"] == "1"; let forceAccessibilityTrusted = env["PUSHWRITE_LAUNCH_FORCE_ACCESSIBILITY_TRUSTED"] == "1"; let configuration = NSWorkspace.OpenConfiguration(); configuration.activates = false; configuration.createsNewApplicationInstance = true; var arguments = ["--runtime-dir", runtimeDir]; if !simulatedText.isEmpty { arguments.append(contentsOf: ["--simulated-transcription-text", simulatedText]) }; if forceAccessibilityBlocked { arguments.append("--force-accessibility-blocked") }; if forceAccessibilityTrusted { arguments.append("--force-accessibility-trusted") }; configuration.arguments = arguments; let semaphore = DispatchSemaphore(value: 0); var launchError: Error?; NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: productAppPath), configuration: configuration) { _, error in launchError = error; semaphore.signal() }; _ = semaphore.wait(timeout: .now() + 10); if let launchError { fputs("PushWrite launch failed: \(launchError)\n", stderr); exit(1) }'

  STATE_FILE="$RUNTIME_DIR/product-state.json"
  ATTEMPTS=$(( TIMEOUT_MS / 100 ))
  if [[ "$ATTEMPTS" -lt 1 ]]; then
    ATTEMPTS=1
  fi

  for ((i=0; i<ATTEMPTS; i++)); do
    if [[ -f "$STATE_FILE" ]]; then
      cat "$STATE_FILE"
      exit 0
    fi
    sleep 0.1
  done

  echo "Timed out waiting for product state file in $RUNTIME_DIR" >&2
  exit 1
fi

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  "$SOURCE_FILE" \
  -o "$TOOL_PATH"

exec "$TOOL_PATH" "$@"
