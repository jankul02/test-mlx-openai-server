#!/bin/zsh
# clean.sh - remove venv, logs, temp files

source ./config.sh

echo "🧹 Cleaning project..."
rm -rf "$VENV_DIR"
rm -rf "$LOG_DIR"
rm -f /tmp/test.png /tmp/test_audio.mp3
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
echo "✨ Done."

echo ""
echo "To also remove Docker containers and volumes:"
echo "  docker rm -f $WEBUI_CONTAINER $TIKA_CONTAINER"
echo "  docker volume rm open-webui-mlx"
echo ""
echo "To remove HuggingFace model cache (~20 GB):"
echo "  huggingface-cli delete-cache"
echo "  # or manually:"
echo "  rm -rf ~/.cache/huggingface/hub/models--mlx-community--gemma-4-26b-a4b-it-6bit"
