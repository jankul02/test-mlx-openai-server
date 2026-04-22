#!/bin/zsh
# clean.sh - usuwa venv, logi, pliki tymczasowe

source ./config.sh

echo "🧹 Czyszczenie projektu..."
rm -rf "$VENV_DIR"
rm -rf "$LOG_DIR"
rm -f /tmp/test_vision.png /tmp/test_audio.mp3
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
echo "✨ Gotowe."

echo ""
echo "Aby usunąć Docker kontenery i dane czatu:"
echo "  docker rm -f $WEBUI_CONTAINER $TIKA_CONTAINER $SEARXNG_CONTAINER"
echo "  docker volume rm open-webui-mlx"
echo ""
echo "Aby usunąć modele (~23 GB):"
echo "  rm -rf ~/.cache/huggingface/hub/models--mlx-community--gemma-4-26b-a4b-it-6bit"
echo "  rm -rf ~/.cache/huggingface/hub/models--mlx-community--whisper-large-v3-mlx"
