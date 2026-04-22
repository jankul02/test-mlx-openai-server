#!/bin/zsh
# config.sh - shared configuration, sourced by all scripts

# ── Model ───────────────────────────────────────────────
MODEL_PATH="mlx-community/gemma-4-26b-a4b-it-6bit"
MODEL_TYPE="multimodal"           # multimodal = vision support via mlx-vlm
MODEL_PORT=8090

# ── Whisper (audio transcription) ───────────────────────
WHISPER_PATH="mlx-community/whisper-large-v3-mlx"
WHISPER_PORT=8091

# ── Open WebUI ───────────────────────────────────────────
WEBUI_PORT=3000
WEBUI_CONTAINER="open-webui-mlx"

# ── Tika OCR ─────────────────────────────────────────────
TIKA_CONTAINER="tika"
TIKA_PORT=9998

# ── Paths ────────────────────────────────────────────────
LOG_DIR="./logs"
VENV_DIR=".venv"
