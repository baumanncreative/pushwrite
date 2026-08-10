#!/usr/bin/env python3

import sys
from urllib.parse import parse_qs, urlsplit


def is_allowed_audio_url(url: str, revision: str, row: int) -> bool:
    try:
        parsed = urlsplit(url)
        port = parsed.port
    except ValueError:
        return False

    expected_path = (
        f"/assets/i4ds/SPC_test/--/{revision}/--/default/test/"
        f"{row}/audio/audio.wav"
    )
    try:
        query = parse_qs(parsed.query, keep_blank_values=True, strict_parsing=True)
    except ValueError:
        return False
    expected_query_keys = {"Expires", "Signature", "Key-Pair-Id"}

    return (
        parsed.scheme == "https"
        and parsed.hostname == "datasets-server.huggingface.co"
        and port in (None, 443)
        and parsed.username is None
        and parsed.password is None
        and parsed.path == expected_path
        and parsed.fragment == ""
        and set(query) == expected_query_keys
        and all(len(values) == 1 and values[0] for values in query.values())
    )


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: validate_swiss_asr_audio_url.py <url> <revision> <row>", file=sys.stderr)
        return 64
    try:
        row = int(sys.argv[3])
    except ValueError:
        return 64
    return 0 if is_allowed_audio_url(sys.argv[1], sys.argv[2], row) else 1


if __name__ == "__main__":
    raise SystemExit(main())
