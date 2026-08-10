#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLI_PATH="${PUSHWRITE_LOCAL_TEXT_CLI_PATH:-$ROOT_DIR/build/llamacpp/build/bin/llama-completion}"
MODEL_PATH="${PUSHWRITE_LOCAL_TEXT_MODEL_PATH:-$ROOT_DIR/models/qwen2.5-1.5b-instruct-q4_k_m.gguf}"
OUTPUT_DIR="${PUSHWRITE_LOCAL_TEXT_VALIDATION_DIR:-}"
SDK_PATH="${PUSHWRITE_SDK_PATH:-$(xcrun --show-sdk-path)}"

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$(mktemp -d /tmp/pushwrite-local-text-validation.XXXXXXXX)"
  trap 'rm -rf "$OUTPUT_DIR"' EXIT INT TERM
elif [[ -e "$OUTPUT_DIR" || -L "$OUTPUT_DIR" ]]; then
  echo "Explicit validation output directory must not already exist: $OUTPUT_DIR" >&2
  exit 64
else
  mkdir -m 700 -p "$OUTPUT_DIR"
fi
PROMPT_BUILDER="$OUTPUT_DIR/build_local_text_prompt"

if [[ ! -x "$CLI_PATH" ]]; then
  echo "Missing executable local text runtime: $CLI_PATH" >&2
  exit 1
fi
if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Missing local text model: $MODEL_PATH" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR/module-cache"
xcrun swiftc \
  -module-cache-path "$OUTPUT_DIR/module-cache" \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos13.0 \
  "$ROOT_DIR/core/workflow/PushWriteCore.swift" \
  "$ROOT_DIR/scripts/build_local_text_prompt.swift" \
  -o "$PROMPT_BUILDER"

run_case() {
  local name="$1"
  local source="$2"
  local target="$3"
  local transcript="$4"
  shift 4
  local prompt_path="$OUTPUT_DIR/$name.prompt.txt"
  local output_path="$OUTPUT_DIR/$name.output.txt"
  local stderr_path="$OUTPUT_DIR/$name.stderr.txt"

  local source_family="${source%%-*}"
  if [[ "$source" != "auto" && "$source_family" != "$target" && "$source_family" != "en" && "$target" != "en" ]]; then
    local pivot_prompt_path="$OUTPUT_DIR/$name.pivot.prompt.txt"
    local pivot_output_path="$OUTPUT_DIR/$name.pivot.output.txt"
    local pivot_stderr_path="$OUTPUT_DIR/$name.pivot.stderr.txt"
    "$PROMPT_BUILDER" "$source" en "$transcript" > "$pivot_prompt_path"
    chmod 600 "$pivot_prompt_path"
    /usr/bin/sandbox-exec \
      -p '(version 1) (allow default) (deny network*)' \
      "$CLI_PATH" \
      --offline \
      --model "$MODEL_PATH" \
      --system-prompt "$("$PROMPT_BUILDER" --system-prompt)" \
      --file "$pivot_prompt_path" \
      --ctx-size 2048 \
      --n-predict 256 \
      --seed 42 \
      --temp 0.1 \
      --top-k 20 \
      --top-p 0.8 \
      --repeat-penalty 1.05 \
      --jinja \
      --single-turn \
      --no-display-prompt \
      --no-perf \
      --no-warmup \
      --color off > "$pivot_output_path" 2> "$pivot_stderr_path"
    perl -0pi -e 's/\s*(?:\[end of text\]|<\|endoftext\|>|<\|im_end\|>)\s*\z//g' "$pivot_output_path"
    if [[ ! -s "$pivot_output_path" ]]; then
      echo "$name produced no English pivot output." >&2
      exit 1
    fi
    transcript="$(<"$pivot_output_path")"
    source=en
  fi

  "$PROMPT_BUILDER" "$source" "$target" "$transcript" > "$prompt_path"
  chmod 600 "$prompt_path"
  /usr/bin/sandbox-exec \
    -p '(version 1) (allow default) (deny network*)' \
    "$CLI_PATH" \
    --offline \
    --model "$MODEL_PATH" \
    --system-prompt "$("$PROMPT_BUILDER" --system-prompt)" \
    --file "$prompt_path" \
    --ctx-size 2048 \
    --n-predict 256 \
    --seed 42 \
    --temp 0.1 \
    --top-k 20 \
    --top-p 0.8 \
    --repeat-penalty 1.05 \
    --jinja \
    --single-turn \
    --no-display-prompt \
    --no-perf \
    --no-warmup \
    --color off > "$output_path" 2> "$stderr_path"

  perl -0pi -e 's/\s*(?:\[end of text\]|<\|endoftext\|>|<\|im_end\|>)\s*\z//g' "$output_path"
  if [[ ! -s "$output_path" ]]; then
    echo "$name produced no output." >&2
    exit 1
  fi
  local expected
  for expected in "$@"; do
    if ! grep -Eiq "$expected" "$output_path"; then
      echo "$name is missing expected pattern '$expected'. Output:" >&2
      sed -n '1,20p' "$output_path" >&2
      exit 1
    fi
  done
  if grep -Eiq '^(Here is|Translation:|Übersetzung:|Traducción:|Traduction:)' "$output_path"; then
    echo "$name returned commentary instead of insertable text." >&2
    exit 1
  fi
  printf '%s: passed\n' "$name"
}

run_case \
  german-to-english \
  de-DE \
  en \
  "Heute um 17 Uhr habe ich Zeit für einen Termin, und morgen treffe ich Anna Meyer." \
  'today' '(17|5:00 ?PM)' 'time' '(appointment|meeting)' 'tomorrow' 'Anna' 'Meyer'
run_case \
  english-to-spanish \
  en \
  es \
  "Today at 17:00 I have time for an appointment, and tomorrow I will meet Anna Meyer." \
  'hoy' '(17|5:00 ?PM)' '(cita|reuni[oó]n)' 'mañana' 'Anna' 'Meyer'
run_case \
  english-to-french \
  en \
  fr \
  "Today at 17:00 I have time for an appointment, and tomorrow I will meet Anna Meyer." \
  "aujourd'hui" '(17|5:00 ?PM)' '(rendez-vous|r[eé]union)' 'demain' 'Anna' 'Meyer'
run_case \
  english-to-german \
  en \
  de \
  "Today at 17:00 I have time for an appointment, and tomorrow I will meet Anna Meyer." \
  'heute' '(17|5:00 ?PM)' 'Zeit' '(Termin|Treffen)' 'morgen' 'Anna' 'Meyer'
run_case \
  german-to-spanish \
  de-DE \
  es \
  "Heute um 17 Uhr habe ich Zeit für einen Termin, und morgen treffe ich Anna Meyer." \
  'hoy' '(17|5:00 ?PM)' '(cita|reuni[oó]n)' 'mañana' 'Anna' 'Meyer'
run_case \
  german-to-french \
  de-DE \
  fr \
  "Heute um 17 Uhr habe ich Zeit für einen Termin, und morgen treffe ich Anna Meyer." \
  "aujourd'hui" '(17|5:00 ?PM)' '(rendez-vous|r[eé]union)' 'demain' 'Anna' 'Meyer'
run_case \
  spanish-to-english \
  es \
  en \
  "Hoy a las 17:00 tengo tiempo para una cita y mañana me reúno con Anna Meyer." \
  'today' '(17|5:00 ?PM)' '(appointment|meeting)' 'tomorrow' 'Anna' 'Meyer'
run_case \
  spanish-to-german \
  es \
  de \
  "Hoy a las 17:00 tengo tiempo para una cita y mañana me reúno con Anna Meyer." \
  'heute' '(17|5:00 ?PM)' '(Termin|Treffen)' 'morgen' 'Anna' 'Meyer'
run_case \
  spanish-to-french \
  es \
  fr \
  "Hoy a las 17:00 tengo tiempo para una cita y mañana me reúno con Anna Meyer." \
  "aujourd'hui" '(17|5:00 ?PM)' '(rendez-vous|r[eé]union)' 'demain' 'Anna' 'Meyer'
run_case \
  french-to-english \
  fr \
  en \
  "Aujourd'hui à 17 h, j'ai du temps pour un rendez-vous et demain je rencontre Anna Meyer." \
  'today' '(17|5:00 ?PM)' '(appointment|meeting)' 'tomorrow' 'Anna' 'Meyer'
run_case \
  french-to-german \
  fr \
  de \
  "Aujourd'hui à 17 h, j'ai du temps pour un rendez-vous et demain je rencontre Anna Meyer." \
  'heute' '(17|5:00 ?PM)' '(Termin|Treffen)' 'morgen' 'Anna' 'Meyer'
run_case \
  french-to-spanish \
  fr \
  es \
  "Aujourd'hui à 17 h, j'ai du temps pour un rendez-vous et demain je rencontre Anna Meyer." \
  'hoy' '(17|5:00 ?PM)' '(cita|reuni[oó]n)' 'mañana' 'Anna' 'Meyer'
printf '%s\n' "LocalTextTransformationValidation: 12 passed"
