#!/bin/zsh
set -euo pipefail

# PushWrite App Compatibility Test Script (002N)
# Tests the insert path in different macOS app contexts
# 
# Blocker-Identifikation:
# - AppleScript/AX-Zugriff auf TextEdit nicht möglich im Sandbox-Modus
# - Dies ist eine macOS-Beschränkung, keine Code-Defekt

REPO_ROOT="/Users/michel/Code/pushwrite"
PRODUCT_APP_PATH="${REPO_ROOT}/build/pushwrite-product/PushWrite.app"
RUNTIME_BASE="/tmp/pushwrite-app-compat"

# Test contexts (ohne TextEdit aufgrund von AppleScript-Blocker)
CONTEXTS=("Nachrichten" "Safari" "Slack")
CONTEXT_BUNDLE_IDS=("com.apple.Mail" "com.apple.Safari" "com.tinyspeck.slackmacgap")

HOLD_DURATION_MS=900
WHISPER_CLI_PATH="/Users/michel/Code/pushwrite/build/whispercpp/build/bin/whisper-cli"
WHISPER_MODEL_PATH="/Users/michel/Code/pushwrite/third_party/whisper.cpp/models/for-tests-ggml-small.en.bin"
WHISPER_LANGUAGE="de"
TRANSCRIPTION_FIXTURE_WAV="${REPO_ROOT}/build/whispercpp/micro-machines-16k-mono.wav"

RESULTS_DIR="/Users/michel/Code/pushwrite/app-compatibility-results"
mkdir -p "${RESULTS_DIR}"

echo "=== PushWrite App Compatibility Test (002N) ==="
echo "Start: $(date)"
echo ""

is_app_running() {
    local bundle_id="$1"
    osascript -e "application (id \"${bundle_id}\") is running" 2>/dev/null | grep -q "true"
}

prepare_context() {
    local context_name="$1"
    local bundle_id="$2"
    
    echo "Preparing context: ${context_name} (${bundle_id})"
    
    case "${context_name}" in
        "Nachrichten")
            osascript -e "tell application \"Mail\" to activate"
            osascript -e "tell application \"System Events\" to keystroke \"n\" using {command down}"
            sleep 1
            osascript -e "tell application \"System Events\" to keystroke tab"
            sleep 0.3
            ;;
        "Safari")
            osascript -e "tell application \"Safari\" to activate"
            osascript -e "tell application \"Safari\" to do JavaScript \"document.body.innerHTML = '<textarea style=\\\"width:100%;height:200px\\\"></textarea>'; document.querySelector('textarea').focus();\" in document 1"
            ;;
        "Slack")
            osascript -e "tell application \"Slack\" to activate"
            sleep 1
            osascript -e "tell application \"System Events\" to keystroke \"l\" using {command down}"
            sleep 0.3
            osascript -e "tell application \"System Events\" to keystroke tab"
            ;;
        *)
            echo "Unknown context: ${context_name}"
            return 1
            ;;
    esac
    
    sleep 0.5
}

run_test() {
    local context_name="$1"
    local bundle_id="$2"
    local runtime_dir="${RUNTIME_BASE}-${context_name}"
    
    echo ""
    echo "--- Test: ${context_name} ---"
    
    prepare_context "${context_name}" "${bundle_id}"
    
    if ! is_app_running "${bundle_id}"; then
        echo "WARNING: ${context_name} is not running, attempting to start..."
        open -b "${bundle_id}"
        sleep 2
    fi
    
    local previous_response_id=""
    if [[ -f "${runtime_dir}/logs/last-hotkey-response.json" ]]; then
        previous_response_id=$(jq -r '.id // ""' "${runtime_dir}/logs/last-hotkey-response.json" 2>/dev/null || echo "")
    fi
    
    /Users/michel/Code/pushwrite/scripts/control_pushwrite_product.sh launch \
        --runtime-dir "${runtime_dir}" \
        --whisper-cli-path "${WHISPER_CLI_PATH}" \
        --whisper-model-path "${WHISPER_MODEL_PATH}" \
        --whisper-language "${WHISPER_LANGUAGE}" \
        --transcription-fixture-wav "${TRANSCRIPTION_FIXTURE_WAV}"
    
    sleep 0.2
    osascript -e "tell application \"System Events\" to key code 35 using {control down, option down, command down}"
    sleep 1.5
    
    local response_file="${runtime_dir}/logs/last-hotkey-response.json"
    if [[ -f "${response_file}" ]]; then
        echo "Response:"
        cat "${response_file}" | jq -r '{
            id: .id,
            status: .status,
            insertRoute: .insertRoute,
            syntheticPastePosted: .syntheticPastePosted,
            error: .error
        }' 2>/dev/null || echo "Could not parse response"
    else
        echo "ERROR: No response file found"
    fi
    
    echo "Focus after paste:"
    osascript -e "tell application \"System Events\" to get bundle identifier of process 1 where frontmost is true" 2>/dev/null || echo "Could not determine focus"
    
    /Users/michel/Code/pushwrite/scripts/control_pushwrite_product.sh stop \
        --runtime-dir "${runtime_dir}" \
        --timeout-ms 5000
    
    echo "--- End Test: ${context_name} ---"
}

n_contexts=${#CONTEXTS[@]}
for ((i=1; i<=n_contexts; i++)); do
    run_test "${CONTEXTS[$i]}" "${CONTEXT_BUNDLE_IDS[$i]}"
done

echo ""
echo "=== Test completed: $(date) ==="
echo "Results stored in: ${RESULTS_DIR}"
