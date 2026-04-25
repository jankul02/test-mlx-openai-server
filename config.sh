#!/bin/zsh
# config.sh - shared configuration, sourced by all scripts
# ── LM Studio (główny model) ─────────────────────────────
LM_STUDIO_PORT=1234          # LM Studio API (uruchamiasz ręcznie jako app)

# ── Whisper (audio transcription) ───────────────────────
WHISPER_PATH="mlx-community/whisper-large-v3-mlx"
WHISPER_PORT=8091

# ── SearXNG (web search) ─────────────────────────────────
SEARXNG_PORT=8889
SEARXNG_CONTAINER="searxng"
SEARXNG_CONFIG_DIR="$HOME/searxng-config"

# ── Tika OCR (scanned PDFs) ──────────────────────────────
TIKA_PORT=9998
TIKA_CONTAINER="tika"

# ── Paths ────────────────────────────────────────────────
LOG_DIR="./logs"
VENV_DIR=".venv"
PROJECTS_DIR="$HOME/projects"