#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODEL_PATH="$ROOT_DIR/models/ggml-large-v3-q5_0.bin"
PARTIAL_PATH="$MODEL_PATH.partial"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-large-v3-q5_0.bin?download=true"
EXPECTED_SIZE=1081140203
EXPECTED_SHA1="e6e2ed78495d403bef4b7cff42ef4aaadcfea8de"
EXPECTED_SHA256="d75795ecff3f83b5faa89d1900604ad8c780abd5739fae406de19f23ecd98ad1"

verify_model() {
  local model_file="$1"
  [[ -f "$model_file" ]] || return 1
  [[ "$(stat -f '%z' "$model_file")" == "$EXPECTED_SIZE" ]] || return 1
  [[ "$(shasum "$model_file" | awk '{print $1}')" == "$EXPECTED_SHA1" ]] || return 1
  [[ "$(shasum -a 256 "$model_file" | awk '{print $1}')" == "$EXPECTED_SHA256" ]]
}

if verify_model "$MODEL_PATH"; then
  printf '%s\n' "$MODEL_PATH"
  exit 0
fi

mkdir -p "$ROOT_DIR/models"
curl \
  --location \
  --fail \
  --retry 50 \
  --retry-all-errors \
  --retry-delay 2 \
  --connect-timeout 30 \
  --continue-at - \
  --output "$PARTIAL_PATH" \
  "$MODEL_URL"

if ! verify_model "$PARTIAL_PATH"; then
  echo "Downloaded Whisper model failed size or checksum verification." >&2
  exit 1
fi

mv "$PARTIAL_PATH" "$MODEL_PATH"
printf '%s\n' "$MODEL_PATH"
