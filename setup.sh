#!/bin/zsh
# setup.sh - jednorazowa instalacja zależności
# Bezpieczne do wielokrotnego uruchomienia (idempotent)

source ./config.sh

echo "🔧 Setup: test-mlx-openai-server"
echo ""

# ── Python 3.11 ──────────────────────────────────────────
if ! command -v python3.11 &>/dev/null; then
  echo "📦 Instaluję Python 3.11..."
  brew install python@3.11
else
  echo "✅ Python 3.11: $(python3.11 --version)"
fi

# ── Node.js (wymagany przez OpenClaw) ────────────────────
if ! command -v node &>/dev/null; then
  echo "📦 Instaluję Node.js..."
  brew install node
else
  echo "✅ Node.js: $(node --version)"
fi

# ── Docker ───────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "❌ Docker nie znaleziony. Zainstaluj Docker Desktop."
  exit 1
else
  echo "✅ Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
fi

# ── ffmpeg (Whisper) ─────────────────────────────────────
if ! command -v ffmpeg &>/dev/null; then
  echo "📦 Instaluję ffmpeg..."
  brew install ffmpeg
else
  echo "✅ ffmpeg: $(ffmpeg -version 2>&1 | head -1 | cut -d' ' -f3)"
fi

# ── OpenClaw ─────────────────────────────────────────────
if ! command -v openclaw &>/dev/null; then
  echo "📦 Instaluję OpenClaw..."
  curl -fsSL https://openclaw.ai/install.sh | bash
  echo ""
  echo "⚠️  Po instalacji uruchom: openclaw onboard"
  echo "   Skonfiguruje gateway, workspace i API key"
  echo "   Potem wpisz OPENCLAW_API_KEY w config.sh"
else
  echo "✅ OpenClaw: $(openclaw --version 2>/dev/null || echo 'installed')"
fi

# ── Virtual environment ──────────────────────────────────
if [[ -d "$VENV_DIR" ]]; then
  echo "✅ venv już istnieje ($VENV_DIR)"
else
  echo "🐍 Tworzę Python 3.11 venv..."
  python3.11 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install -q -U pip

echo "📦 Instaluję mlx-vlm (vision server)..."
pip install -q mlx-vlm

echo "📦 Instaluję mlx-openai-server (Whisper)..."
pip install -q mlx-openai-server

echo "📦 Instaluję open-terminal..."
pip install -q open-terminal

echo "📦 Instaluję huggingface_hub..."
pip install -q huggingface_hub

# ── Pobieranie modeli ────────────────────────────────────
echo ""
echo "📥 Sprawdzam modele..."

python3 - <<PYEOF
from huggingface_hub import snapshot_download
import os

cache = os.path.expanduser("~/.cache/huggingface/hub")

def check_model(model_id, label, size):
    model_dir = "models--" + model_id.replace("/", "--")
    if os.path.exists(os.path.join(cache, model_dir)):
        print(f"✅ {label} już pobrany")
    else:
        print(f"📥 Pobieram {label} (~{size})...")
        snapshot_download(model_id)
        print(f"✅ {label} pobrany")

check_model("${MODEL_PATH}", "Gemma 4 26B 6bit", "20 GB")
check_model("${WHISPER_PATH}", "Whisper large-v3", "3 GB")
PYEOF

# ── Katalogi i gitignore ─────────────────────────────────
mkdir -p "$LOG_DIR"

for entry in "${VENV_DIR}/" "logs/" "__pycache__/" "*.pyc" ".DS_Store"; do
  grep -qF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
done

echo ""
echo "✅ Setup zakończony."
echo ""
echo "Następne kroki:"
echo "  1. openclaw onboard          # jeśli jeszcze nie zrobione"
echo "  2. Wpisz OPENCLAW_API_KEY w config.sh"
echo "  3. ./start.sh"
