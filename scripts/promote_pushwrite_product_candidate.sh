#!/bin/zsh

set -euo pipefail

echo "Manual product-candidate promotion was retired for PushWrite 0.3.0." >&2
echo "Use scripts/build_pushwrite_release.sh to build, sign, validate, and package a stable release from source." >&2
exit 64
