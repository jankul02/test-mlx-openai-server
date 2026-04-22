#!/bin/zsh
# setup.sh - install mlx-openai-server and dependencies
# Safe to re-run (idempotent)

source ./config.sh

echo "🔧 Setting up test-mlx-openai-server..."
echo ""

# ── Python 3.11 (required by mlx-openai-server) ─────────
if ! command -v python3.11 &>/dev/null; then
  echo "📦 Installing Python 3.11..."
  brew install python@3.11
else
  echo "✅ Python 3.11: $(python3.11 --version)"
fi

# ── Docker ───────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "❌ Docker not found. Install Docker Desktop first."
  exit 1
else
  echo "✅ Docker available"
fi

# ── ffmpeg (for Whisper audio) ───────────────────────────
if ! command -v ffmpeg &>/dev/null; then
  echo "📦 Installing ffmpeg (for Whisper audio transcription)..."
  brew install ffmpeg
else
  echo "✅ ffmpeg available"
fi

# ── Virtual environment ──────────────────────────────────
if [[ -d "$VENV_DIR" ]]; then
  echo "✅ venv already exists at $VENV_DIR"
else
  echo "🐍 Creating Python 3.11 venv..."
  python3.11 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

echo "📦 Installing mlx-openai-server..."
pip install -q -U pip
pip install -q mlx-openai-server

echo "📦 Installing mlx-vlm (vision support)..."
pip install -q mlx-vlm

echo "📦 Installing huggingface_hub..."
pip install -q huggingface_hub

# ── Model download ───────────────────────────────────────
echo ""
echo "📥 Checking model: $MODEL_PATH"
python3 -c "
from huggingface_hub import snapshot_download
import os
cache = os.path.expanduser('~/.cache/huggingface/hub')
model_dir = 'models--' + '$MODEL_PATH'.replace('/', '--')
if os.path.exists(os.path.join(cache, model_dir)):
    print('✅ Model already downloaded')
else:
    print('📥 Downloading $MODEL_PATH (~20 GB)...')
    snapshot_download('$MODEL_PATH')
    print('✅ Model downloaded')
"

# ── Whisper model ────────────────────────────────────────
echo "📥 Checking Whisper model: $WHISPER_PATH"
python3 -c "
from huggingface_hub import snapshot_download
import os
cache = os.path.expanduser('~/.cache/huggingface/hub')
model_dir = 'models--' + '$WHISPER_PATH'.replace('/', '--')
if os.path.exists(os.path.join(cache, model_dir)):
    print('✅ Whisper already downloaded')
else:
    print('📥 Downloading Whisper large-v3 (~3 GB)...')
    snapshot_download('$WHISPER_PATH')
    print('✅ Whisper downloaded')
"

mkdir -p "$LOG_DIR"

# ── gitignore ────────────────────────────────────────────
if ! grep -q "^${VENV_DIR}/" .gitignore 2>/dev/null; then
  echo "${VENV_DIR}/" >> .gitignore
fi
if ! grep -q "^logs/" .gitignore 2>/dev/null; then
  echo "logs/" >> .gitignore
fi

echo ""
echo "✅ Setup complete."
echo "   Run: ./start.sh"
