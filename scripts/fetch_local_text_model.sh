#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${${1:-$ROOT_DIR/models}:A}"
MODEL_NAME="qwen2.5-1.5b-instruct-q4_k_m.gguf"
MODEL_PATH="$OUTPUT_DIR/$MODEL_NAME"
PARTIAL_PATH="$MODEL_PATH.partial"
LICENSE_PATH="$OUTPUT_DIR/Qwen2.5-LICENSE.txt"
MODEL_SHA256="183715c435899236895da3869489cc30ac241476b4971a20285b1a462818a5b4"
MODEL_SIZE="986048512"
LICENSE_SHA256="832dd9e00a68dd83b3c3fb9f5588dad7dcf337a0db50f7d9483f310cd292e92e"
REGISTRY_ROOT="https://registry.ollama.ai/v2/library/qwen2.5/blobs"

mkdir -p "$OUTPUT_DIR"

if [[ -f "$MODEL_PATH" ]] \
  && [[ "$(stat -f%z "$MODEL_PATH")" == "$MODEL_SIZE" ]] \
  && [[ "$(shasum -a 256 "$MODEL_PATH" | awk '{print $1}')" == "$MODEL_SHA256" ]]; then
  :
else
  curl \
    --fail \
    --location \
    --retry 5 \
    --retry-delay 2 \
    --continue-at - \
    "$REGISTRY_ROOT/sha256:$MODEL_SHA256" \
    --output "$PARTIAL_PATH"

  ACTUAL_SIZE="$(stat -f%z "$PARTIAL_PATH")"
  if [[ "$ACTUAL_SIZE" != "$MODEL_SIZE" ]]; then
    echo "Unexpected local text model size: expected $MODEL_SIZE, got $ACTUAL_SIZE" >&2
    exit 1
  fi
  ACTUAL_SHA256="$(shasum -a 256 "$PARTIAL_PATH" | awk '{print $1}')"
  if [[ "$ACTUAL_SHA256" != "$MODEL_SHA256" ]]; then
    echo "Local text model SHA-256 mismatch: expected $MODEL_SHA256, got $ACTUAL_SHA256" >&2
    exit 1
  fi
  mv "$PARTIAL_PATH" "$MODEL_PATH"
fi

if [[ ! -f "$LICENSE_PATH" ]] \
  || [[ "$(shasum -a 256 "$LICENSE_PATH" | awk '{print $1}')" != "$LICENSE_SHA256" ]]; then
  curl \
    --fail \
    --location \
    --retry 5 \
    --retry-delay 2 \
    "$REGISTRY_ROOT/sha256:$LICENSE_SHA256" \
    --output "$LICENSE_PATH"
fi
ACTUAL_LICENSE_SHA256="$(shasum -a 256 "$LICENSE_PATH" | awk '{print $1}')"
if [[ "$ACTUAL_LICENSE_SHA256" != "$LICENSE_SHA256" ]]; then
  echo "Qwen2.5 license SHA-256 mismatch: expected $LICENSE_SHA256, got $ACTUAL_LICENSE_SHA256" >&2
  exit 1
fi

printf '%s  %s\n' "$MODEL_SHA256" "$MODEL_NAME" > "$OUTPUT_DIR/local-text-model.sha256"
printf '%s  %s\n' "$LICENSE_SHA256" "Qwen2.5-LICENSE.txt" > "$OUTPUT_DIR/local-text-license.sha256"
printf '%s\n' "$MODEL_PATH"
