# Building PushWrite

## Prerequisites

- Apple-Silicon Mac
- macOS 13 or newer
- Apple Command Line Tools with `swiftc`, `cmake`, `codesign`, `hdiutil` and an SDK compatible with the active Swift compiler
- verified Whisper model cache `models/ggml-large-v3-q5_0.bin`
- fetched and verified local text model `models/qwen2.5-1.5b-instruct-q4_k_m.gguf`

No network access is required once the repository and model are present.

The runtime builders accept `cmake` from `PATH` only when macOS verifies the
Kitware Developer ID signature (`W38PE5Y733`). For an explicitly reviewed
standalone binary, its absolute path and SHA-256 must both be set:

```sh
export PUSHWRITE_CMAKE_BIN=/absolute/path/to/cmake
export PUSHWRITE_CMAKE_SHA256=<64-lowercase-hex-digest>
```

Repository-local build caches and unsigned PATH executables are never selected
implicitly.

## Reproducible build

```sh
export PUSHWRITE_SDK_PATH="$(xcrun --show-sdk-path)"
./scripts/run_pushwrite_unit_tests.sh
./scripts/build_whispercpp_minimal.sh
./scripts/fetch_whisper_model.sh
./scripts/fetch_local_text_model.sh
./scripts/build_llamacpp_minimal.sh
./scripts/run_local_text_transformation_validation.sh
./scripts/build_pushwrite_product.sh /tmp/pushwrite-product
```

If the active SDK/compiler pair is inconsistent, select a matching installed SDK, for example:

```sh
export PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
```

The app builder refuses to write directly into the stable QA bundle path. Promotion is an explicit separate step.

## Release package

Stable Developer ID release:

```sh
export PUSHWRITE_CODESIGN_IDENTITY="Developer ID Application: ORGANISATION (TEAMID)"
export PUSHWRITE_NOTARY_PROFILE="PUSHWRITE_NOTARY"
export PUSHWRITE_TEAM_ID="TEAMID1234"
./scripts/build_pushwrite_release.sh
```

The named keychain profile must be created outside the repository with `xcrun notarytool store-credentials`. Never place credentials in scripts or Git.

The stable release script refuses missing credentials. It signs the nested CLIs before compiling their pinned hashes into the app, enables hardened runtime, verifies the exact Team ID, rejects repository-local dynamic dependencies, notarizes and staples the app and DMG, assesses both with Gatekeeper, and emits ZIP/DMG SHA-256 sums plus metadata. `build_pushwrite_product.sh` may still create an ad-hoc development app, but that output is not publishable.

Apple requires Developer ID, hardened runtime and secure timestamps for notarization: [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
