#!/bin/zsh
# stop.sh - stop all services
# Reentrant: safe to run if any or all services already stopped

source ./config.sh

# ── Helper ───────────────────────────────────────────────
port_in_use() { lsof -i ":$1" -sTCP:LISTEN &>/dev/null }

# ── Open WebUI ───────────────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q "^${WEBUI_CONTAINER}$"; then
  echo "🛑 Stopping Open WebUI..."
  docker stop "$WEBUI_CONTAINER"
  echo "✅ Open WebUI stopped"
else
  echo "✅ Open WebUI already stopped"
fi

# ── Tika ─────────────────────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q "^${TIKA_CONTAINER}$"; then
  echo "🛑 Stopping Tika..."
  docker stop "$TIKA_CONTAINER"
  echo "✅ Tika stopped"
else
  echo "✅ Tika already stopped"
fi

# ── Whisper ──────────────────────────────────────────────
if port_in_use $WHISPER_PORT; then
  echo "🛑 Stopping Whisper..."
  lsof -ti ":${WHISPER_PORT}" | xargs kill -9 2>/dev/null
  echo "✅ Whisper stopped"
else
  echo "✅ Whisper already stopped"
fi

# ── mlx-openai-server ────────────────────────────────────
if port_in_use $MODEL_PORT; then
  echo "🛑 Stopping mlx-openai-server..."
  lsof -ti ":${MODEL_PORT}" | xargs kill -9 2>/dev/null
  sleep 2
  echo "✅ mlx-openai-server stopped"
else
  echo "✅ mlx-openai-server already stopped"
fi

echo ""
echo "✅ All services stopped"
