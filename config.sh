#!/bin/zsh
# config.sh - shared configuration, sourced by all scripts
# Zmień tu — zmiany propagują się do wszystkich skryptów

# ── Model (vision via mlx_vlm.server) ───────────────────
MODEL_PATH="mlx-community/gemma-4-26b-a4b-it-6bit"
MODEL_PORT=8090

# ── Whisper (audio transcription) ───────────────────────
WHISPER_PATH="mlx-community/whisper-large-v3-mlx"
WHISPER_PORT=8091

# ── SearXNG (web search) ─────────────────────────────────
SEARXNG_PORT=8889
SEARXNG_CONTAINER="searxng"

# ── Tika OCR (scanned PDFs) ──────────────────────────────
TIKA_PORT=9998
TIKA_CONTAINER="tika"

# ── Open WebUI ───────────────────────────────────────────
WEBUI_PORT=3000
WEBUI_CONTAINER="open-webui-mlx"

# ── OpenClaw (autonomous agent) ──────────────────────────
OPENCLAW_PORT=18789
OPENCLAW_API_KEY="sk-openclaw-local"   # odkomentuj po openclaw onboard

# ── Paths ────────────────────────────────────────────────
LOG_DIR="./logs"
VENV_DIR=".venv"
PROJECTS_DIR="$HOME/projects"     # podmontowany do Open WebUI

# ── SearXNG config path ─────────────────────────────────
SEARXNG_CONFIG_DIR="$HOME/searxng-config"
