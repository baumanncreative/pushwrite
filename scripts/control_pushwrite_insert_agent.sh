#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/scripts/control_pushwrite_insert_agent.swift"
OUTPUT_DIR="/tmp/pushwrite-insert-agent-tools"
MODULE_CACHE_DIR="$OUTPUT_DIR/module-cache"
TOOL_PATH="$OUTPUT_DIR/control_pushwrite_insert_agent"
SDK_PATH="$(xcrun --show-sdk-path)"

mkdir -p "$OUTPUT_DIR" "$MODULE_CACHE_DIR"

COMMAND="${1:-}"

if [[ "$COMMAND" == "launch" ]]; then
  AGENT_APP_PATH="${PUSHWRITE_AGENT_APP_PATH:-/tmp/pushwrite-insert-agent-build/PushWriteInsertAgent.app}"
  RUNTIME_DIR="${PUSHWRITE_AGENT_RUNTIME_DIR:-/tmp/pushwrite-insert-agent}"
  TIMEOUT_MS=10000
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent-app)
        AGENT_APP_PATH="$2"
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
      *)
        echo "Unknown argument: $1" >&2
        exit 64
        ;;
    esac
  done

  mkdir -p "$RUNTIME_DIR"
  open -a "$AGENT_APP_PATH" --args --runtime-dir "$RUNTIME_DIR"

  STATE_FILE="$RUNTIME_DIR/agent-state.json"
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

  echo "Timed out waiting for agent state file in $RUNTIME_DIR" >&2
  exit 1
fi

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  "$SOURCE_FILE" \
  -o "$TOOL_PATH"

exec "$TOOL_PATH" "$@"
