#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "The Alpha release path is retired; building the stable release." >&2
exec "$ROOT_DIR/scripts/build_pushwrite_release.sh" "$@"
