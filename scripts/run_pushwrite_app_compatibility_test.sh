#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_APP_PATH="$ROOT_DIR/build/pushwrite-product/PushWrite.app"
RUNTIME_ROOT="/tmp/pushwrite-app-compatibility"
RESULTS_FILE="$ROOT_DIR/build/pushwrite-product/app-compatibility-results.json"
TEXTEDIT_RUNS=5
SAFARI_RUNS=5

usage() {
  cat <<USAGE
Usage: scripts/run_pushwrite_app_compatibility_test.sh [options]

Runs the supported alpha compatibility matrix against native TextEdit and a
local Safari textarea fixture. Each run verifies target focus, inserted text,
pasteboard preservation, and the pasteboard-free insertion route.

Options:
  --product-app-path <path>  App bundle to validate
  --runtime-root <path>      Runtime root (default: /tmp/pushwrite-app-compatibility)
  --results-file <path>      JSON result path
  --textedit-runs <count>    TextEdit repetitions (default: 5)
  --safari-runs <count>      Safari repetitions (default: 5)
  -h, --help                 Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --product-app-path)
      PRODUCT_APP_PATH="$2"
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
    --textedit-runs)
      TEXTEDIT_RUNS="$2"
      shift 2
      ;;
    --safari-runs)
      SAFARI_RUNS="$2"
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
RUNTIME_ROOT="${RUNTIME_ROOT:A}"
RESULTS_FILE="${RESULTS_FILE:A}"

if [[ "$TEXTEDIT_RUNS" != <-> || "$SAFARI_RUNS" != <-> ]]; then
  echo "Run counts must be non-negative integers." >&2
  exit 64
fi

if [[ ! -d "$PRODUCT_APP_PATH" ]]; then
  "$ROOT_DIR/scripts/build_pushwrite_product.sh" "${PRODUCT_APP_PATH:h}"
fi

rm -rf "$RUNTIME_ROOT"
mkdir -p "${RESULTS_FILE:h}"

"$ROOT_DIR/scripts/control_pushwrite_product.sh" \
  launch \
  --force-accessibility-trusted \
  --product-app "$PRODUCT_APP_PATH" \
  --runtime-dir "$RUNTIME_ROOT" >/dev/null

exec "$ROOT_DIR/scripts/run_pushwrite_product_validation.sh" \
  --product-app-path "$PRODUCT_APP_PATH" \
  --skip-build \
  --skip-launch \
  --textedit-runs "$TEXTEDIT_RUNS" \
  --safari-runs "$SAFARI_RUNS" \
  --product-runtime-dir "$RUNTIME_ROOT" \
  --results-file "$RESULTS_FILE"
