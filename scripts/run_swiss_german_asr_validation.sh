#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WHISPER_CLI="${PUSHWRITE_WHISPER_CLI_PATH:-$ROOT_DIR/build/whispercpp/build/bin/whisper-cli}"
WHISPER_MODEL="${PUSHWRITE_WHISPER_MODEL_PATH:-$ROOT_DIR/models/ggml-large-v3-q5_0.bin}"
DATASET="i4ds/SPC_test"
DATASET_REVISION="48c389fb6b88c8e80f03273a677a422729183e06"
SAMPLE_COUNT=5
MAXIMUM_AGGREGATE_WER=0.40
REVISION_MAX_BYTES=1048576
ROWS_MAX_BYTES=10485760
AUDIO_MAX_BYTES=52428800
URL_VALIDATOR="$ROOT_DIR/scripts/validate_swiss_asr_audio_url.py"
REFERENCE_SENTENCES=(
  'Dafür sollen in der Stadt zwei offene Schlitze von je 175 Meter Länge gebaut werden, die sehr viel Platz benötigen und für die viele Häuser abgerissen werden müssten.'
  '– Dies hätte zur Folge, dass 100 Wohn- und Geschäftsliegenschaften weiterhin im Gefahrenbereich liegen würden;'
  'Das Bauen ausserhalb der Bauzone hat in unserem Kanton einen sehr hohen Stellenwert.'
  'Ortstafeln stehen nicht immer im Siedlungsgebiet.'
  'Geschätzte Damen und Herren, das ist für das menschliche Ohr nicht einmal wahrnehmbar!'
)
AUDIO_SHA256=(
  1f29dac1d454c7c4de9c4492e37e83ff76655487c559cf3161b66f93af2c15e1
  091b254d112db34954f1ff6bcdf665bcddab719507f0267e15dd3313db15a359
  32fae5784ad7eebba28825bad6bf15cf6b8ccbaed14da614fbc8052fd96a1249
  cc682b9ddab55de281e4e68728cc71f2238834d00dd21a75b78c014cac5c5c67
  1f2fb72c39d1fd3af64c822e676a7f4c71e643b03daf3784fd2e5cdfbf27e37c
)

if [[ ! -x "$WHISPER_CLI" || ! -f "$WHISPER_MODEL" ]]; then
  echo "Swiss German ASR validation requires the local Whisper runtime and model." >&2
  exit 1
fi
if [[ ! -f "$URL_VALIDATOR" ]]; then
  echo "Missing Swiss German fixture URL validator: $URL_VALIDATOR" >&2
  exit 1
fi
for command in curl jq python3; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing validation dependency: $command" >&2
    exit 1
  fi
done

SCRATCH_ROOT="$(mktemp -d /tmp/pushwrite-swiss-asr.XXXXXXXX)"
trap 'rm -rf "$SCRATCH_ROOT"' EXIT INT TERM

CURRENT_REVISION="$(
  curl -fsS --proto '=https' --max-redirs 0 --max-time 30 --max-filesize "$REVISION_MAX_BYTES" \
    "https://huggingface.co/api/datasets/$DATASET/revision/main" \
    | jq -r .sha
)"
if [[ "$CURRENT_REVISION" != "$DATASET_REVISION" ]]; then
  echo "Pinned Swiss Parliaments Corpus revision changed; review before updating." >&2
  exit 1
fi

ROWS_FILE="$SCRATCH_ROOT/rows.json"
curl -fsS --proto '=https' --max-redirs 0 --max-time 60 --max-filesize "$ROWS_MAX_BYTES" \
  'https://datasets-server.huggingface.co/first-rows?dataset=i4ds%2FSPC_test&config=default&split=test' \
  -o "$ROWS_FILE"
if [[ "$(jq -r .dataset "$ROWS_FILE")" != "$DATASET" ]]; then
  echo "Dataset server returned an unexpected dataset." >&2
  exit 1
fi
if [[ "$(jq '.rows | length' "$ROWS_FILE")" -lt "$SAMPLE_COUNT" ]]; then
  echo "Dataset server returned fewer rows than the pinned ASR fixture set." >&2
  exit 1
fi

for row in {0..4}; do
  REFERENCE_PATH="$SCRATCH_ROOT/$row.reference.txt"
  AUDIO_PATH="$SCRATCH_ROOT/$row.wav"
  OUTPUT_BASE="$SCRATCH_ROOT/$row.hypothesis"
  print -r -- "${REFERENCE_SENTENCES[$((row + 1))]}" > "$REFERENCE_PATH"
  AUDIO_URL="$(jq -r ".rows[$row].row.audio[0].src" "$ROWS_FILE")"
  if ! python3 "$URL_VALIDATOR" "$AUDIO_URL" "$DATASET_REVISION" "$row"; then
    echo "Dataset server returned an audio URL outside the reviewed HTTPS fixture boundary." >&2
    exit 1
  fi
  curl -fsS --proto '=https' --max-redirs 0 --max-time 60 --max-filesize "$AUDIO_MAX_BYTES" \
    "$AUDIO_URL" -o "$AUDIO_PATH"
  ACTUAL_AUDIO_SHA256="$(shasum -a 256 "$AUDIO_PATH" | awk '{print $1}')"
  if [[ "$ACTUAL_AUDIO_SHA256" != "${AUDIO_SHA256[$((row + 1))]}" ]]; then
    echo "Swiss German sample $row failed its pinned SHA-256 check." >&2
    exit 1
  fi
  "$WHISPER_CLI" \
    -m "$WHISPER_MODEL" \
    -f "$AUDIO_PATH" \
    -l auto \
    -nt \
    -otxt \
    -of "$OUTPUT_BASE" >/dev/null 2>"$SCRATCH_ROOT/$row.stderr.txt"
  if [[ ! -s "$OUTPUT_BASE.txt" ]]; then
    echo "Swiss German sample $row produced no transcript." >&2
    exit 1
  fi
done

python3 - "$SCRATCH_ROOT" "$SAMPLE_COUNT" "$MAXIMUM_AGGREGATE_WER" <<'PY'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
sample_count = int(sys.argv[2])
maximum_wer = float(sys.argv[3])

def words(value):
    return re.findall(r"[\wäöüß]+", value.lower())

def distance(left, right):
    row = list(range(len(right) + 1))
    for index, left_word in enumerate(left, 1):
        next_row = [index]
        for offset, right_word in enumerate(right, 1):
            next_row.append(min(
                next_row[-1] + 1,
                row[offset] + 1,
                row[offset - 1] + (left_word != right_word),
            ))
        row = next_row
    return row[-1]

total_errors = 0
total_reference_words = 0
for sample in range(sample_count):
    reference = (root / f"{sample}.reference.txt").read_text().strip()
    hypothesis = (root / f"{sample}.hypothesis.txt").read_text().strip()
    reference_words = words(reference)
    hypothesis_words = words(hypothesis)
    errors = distance(reference_words, hypothesis_words)
    total_errors += errors
    total_reference_words += len(reference_words)
    print(f"sample={sample} wer={errors / max(len(reference_words), 1):.3f}")

if total_reference_words == 0:
    raise SystemExit("Swiss German references contained no words")
aggregate_wer = total_errors / total_reference_words
print(f"aggregate_wer={aggregate_wer:.3f} samples={sample_count}")
if aggregate_wer > maximum_wer:
    raise SystemExit(
        f"aggregate Swiss German WER {aggregate_wer:.3f} exceeds {maximum_wer:.3f}"
    )
PY

printf '%s\n' "SwissGermanASRValidation: $SAMPLE_COUNT passed"
