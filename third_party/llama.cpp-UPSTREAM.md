# Vendored llama.cpp provenance

- Upstream: `https://github.com/ggml-org/llama.cpp`
- Release tag: `b10227`
- Commit: `f5919bf458ef190468b5c329bb293f8a54a1e69c`
- Source archive: `https://github.com/ggml-org/llama.cpp/archive/refs/tags/b10227.tar.gz`
- Source archive SHA-256: `d7b36a3890b813e778db5a74a65a104ebecbf005a61bacabb8b1f24d32dfc2da`
- License: MIT (`llama.cpp/LICENSE`)

PushWrite builds only the `llama-completion` target with OpenSSL, the server,
RPC and subprocess support disabled. The application always starts the runtime
with `--offline` and a bundled, checksum-verified model path.
