#!/bin/zsh

set -euo pipefail

if [[ -n "${PUSHWRITE_CMAKE_BIN:-}" ]]; then
  if [[ "$PUSHWRITE_CMAKE_BIN" != /* ]]; then
    echo "PUSHWRITE_CMAKE_BIN must be an absolute path." >&2
    exit 64
  fi
  if [[ -L "$PUSHWRITE_CMAKE_BIN" || ! -f "$PUSHWRITE_CMAKE_BIN" || ! -x "$PUSHWRITE_CMAKE_BIN" ]]; then
    echo "PUSHWRITE_CMAKE_BIN must name a regular executable, non-symlink file." >&2
    exit 1
  fi
  if [[ ! "${PUSHWRITE_CMAKE_SHA256:-}" =~ '^[0-9a-f]{64}$' ]]; then
    echo "An explicit CMake path requires PUSHWRITE_CMAKE_SHA256 with 64 lowercase hexadecimal characters." >&2
    exit 64
  fi
  CMAKE_BIN="${PUSHWRITE_CMAKE_BIN:A}"
  ACTUAL_SHA256="$(/usr/bin/shasum -a 256 "$CMAKE_BIN" | /usr/bin/awk '{print $1}')"
  if [[ "$ACTUAL_SHA256" != "$PUSHWRITE_CMAKE_SHA256" ]]; then
    echo "CMake digest mismatch: expected $PUSHWRITE_CMAKE_SHA256 but found $ACTUAL_SHA256" >&2
    exit 1
  fi
elif command -v cmake >/dev/null 2>&1; then
  CMAKE_BIN="${$(command -v cmake):A}"
  if [[ ! -f "$CMAKE_BIN" || ! -x "$CMAKE_BIN" ]]; then
    echo "PATH cmake did not resolve to a regular executable file: $CMAKE_BIN" >&2
    exit 1
  fi
  KITWARE_CMAKE_REQUIREMENT='identifier "cmake" and anchor apple generic and certificate leaf[subject.OU] = "W38PE5Y733"'
  if ! /usr/bin/codesign --verify --strict -R="$KITWARE_CMAKE_REQUIREMENT" "$CMAKE_BIN" >/dev/null 2>&1; then
    echo "PATH cmake is not signed by the trusted Kitware Developer ID (W38PE5Y733): $CMAKE_BIN" >&2
    exit 1
  fi
else
  echo "Missing cmake. Install the Kitware-signed binary on PATH or set absolute PUSHWRITE_CMAKE_BIN and pinned PUSHWRITE_CMAKE_SHA256." >&2
  exit 1
fi

printf '%s\n' "$CMAKE_BIN"
