#!/usr/bin/env bash
# run.sh - Portable local LLM launcher (Linux / macOS)
# Boots llamafile's built-in server + web UI, or lets you pick a model interactively.
# Compatible with bash 3.2+ (macOS system bash) - no mapfile/readarray.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME="$DIR/bin/llamafile"
MODELS_DIR="$DIR/models"

if [[ ! -f "$RUNTIME" ]]; then
  echo "ERROR: runtime not found at $RUNTIME"
  echo "Download llamafile from https://github.com/mozilla-ai/llamafile/releases"
  echo "and place it at bin/llamafile"
  exit 1
fi

chmod +x "$RUNTIME" 2>/dev/null || true
# macOS Gatekeeper will block an unsigned downloaded binary by default - clear the quarantine flag.
[[ "$(uname)" == "Darwin" ]] && xattr -d com.apple.quarantine "$RUNTIME" 2>/dev/null || true

# Build model list without mapfile (bash 3.2 compatible)
MODELS=()
while IFS= read -r f; do
  MODELS+=("$f")
done < <(find "$MODELS_DIR" -maxdepth 1 -name "*.gguf" | sort)

if [[ ${#MODELS[@]} -eq 0 ]]; then
  echo "No .gguf models found in $MODELS_DIR"
  echo "Run ./download-models.sh first."
  exit 1
fi

if [[ $# -ge 1 ]]; then
  SELECTED="$1"
else
  echo "Available models:"
  i=1
  for m in "${MODELS[@]}"; do
    NAME="$(basename "$m")"
    SIZE="$(du -h "$m" | cut -f1)"
    printf "  [%d] %-45s (%s)\n" "$i" "$NAME" "$SIZE"
    i=$((i+1))
  done
  read -rp "Select a model [1-${#MODELS[@]}]: " CHOICE
  IDX=$((CHOICE-1))
  if [[ $IDX -lt 0 || $IDX -ge ${#MODELS[@]} ]]; then
    echo "Invalid selection."
    exit 1
  fi
  SELECTED="${MODELS[$IDX]}"
fi

echo "Launching $(basename "$SELECTED") ..."
echo "Web UI will be available at http://127.0.0.1:8080 once loaded."
exec "$RUNTIME" -m "$SELECTED" \
  -c 4096 \
  -t "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)" \
  --host 127.0.0.1 --port 8080
