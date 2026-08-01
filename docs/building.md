# Building PushWrite

## Prerequisites

- Apple-Silicon Mac
- macOS 13 or newer
- Apple Command Line Tools with `swiftc`, `cmake`, `codesign`, `hdiutil` and an SDK compatible with the active Swift compiler
- repository model `models/ggml-tiny.bin`

No network access is required once the repository and model are present.

## Reproducible build

```sh
export PUSHWRITE_SDK_PATH="$(xcrun --show-sdk-path)"
./scripts/run_pushwrite_unit_tests.sh
./scripts/build_whispercpp_minimal.sh
./scripts/build_pushwrite_product.sh /tmp/pushwrite-product
```

If the active SDK/compiler pair is inconsistent, select a matching installed SDK, for example:

```sh
export PUSHWRITE_SDK_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
```

The app builder refuses to write directly into the stable QA bundle path. Promotion is an explicit separate step.

## Release package

Ad-hoc Alpha:

```sh
./scripts/build_pushwrite_alpha_release.sh
```

Developer ID and notarization:

```sh
export PUSHWRITE_CODESIGN_IDENTITY="Developer ID Application: ORGANISATION (TEAMID)"
export PUSHWRITE_NOTARY_PROFILE="PUSHWRITE_NOTARY"
./scripts/build_pushwrite_alpha_release.sh
```

The named keychain profile must be created outside the repository with `xcrun notarytool store-credentials`. Never place credentials in scripts or Git.

The release script signs the nested CLI before the app, enables hardened runtime, verifies the signature, rejects repository-local dynamic dependencies, creates ZIP and DMG artifacts, optionally submits/staples the DMG, and emits SHA-256 sums plus metadata.

Apple requires Developer ID, hardened runtime and secure timestamps for notarization: [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
