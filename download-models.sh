#!/usr/bin/env bash
# download-models.sh
# Pulls the GGUF model quants used by this portable local-LLM build.
# Run this once after cloning the repo, before using run.sh / run.bat.
#
# Requires: curl (or wget as fallback)
# Compatible with bash 3.2+ (macOS system bash) - no associative arrays.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$DIR/models"
mkdir -p "$MODELS_DIR"

# All quants are Q4_K_M - a good balance of size vs quality for CPU inference.
NAME_FAST="llama-3.2-3b-instruct.Q4_K_M.gguf"
URL_FAST="https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"

NAME_DAILY="qwen2.5-7b-instruct.Q4_K_M.gguf"
URL_DAILY="https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q4_K_M.gguf"

NAME_HEAVY="qwen2.5-14b-instruct.Q4_K_M.gguf"
URL_HEAVY="https://huggingface.co/bartowski/Qwen2.5-14B-Instruct-GGUF/resolve/main/Qwen2.5-14B-Instruct-Q4_K_M.gguf"

download() {
  local out="$1"
  local url="$2"
  if [[ -f "$MODELS_DIR/$out" ]]; then
    echo "[skip] $out already exists"
    return
  fi
  echo "[get]  $out"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --progress-bar -o "$MODELS_DIR/$out" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$MODELS_DIR/$out" "$url"
  else
    echo "ERROR: need curl or wget installed." >&2
    exit 1
  fi
}

echo "Downloading models into $MODELS_DIR"
echo "Select which tiers to fetch:"
echo "  [1] Fast only      (~2 GB)   - Llama 3.2 3B"
echo "  [2] Daily driver   (~4.5 GB) - Qwen2.5 7B"
echo "  [3] Heavy          (~9 GB)   - Qwen2.5 14B"
echo "  [4] All three      (~16 GB)"
read -rp "Choice [1-4]: " CHOICE

case "$CHOICE" in
  1) download "$NAME_FAST" "$URL_FAST" ;;
  2) download "$NAME_DAILY" "$URL_DAILY" ;;
  3) download "$NAME_HEAVY" "$URL_HEAVY" ;;
  4)
    download "$NAME_FAST" "$URL_FAST"
    download "$NAME_DAILY" "$URL_DAILY"
    download "$NAME_HEAVY" "$URL_HEAVY"
    ;;
  *) echo "Invalid choice." >&2; exit 1 ;;
esac

echo "Done. Run ./run.sh to start."
