#!/bin/zsh
# start.sh - uruchamia serwisy wspierające
# LM Studio uruchamiaj ręcznie jako app macOS
# Reentrant: bezpieczne gdy serwisy już działają

source ./config.sh
mkdir -p "$LOG_DIR"
source "$VENV_DIR/bin/activate" 2>/dev/null || {
  echo "❌ venv nie znaleziony. Uruchom ./setup.sh"
  exit 1
}

port_in_use()    { lsof -i ":$1" -sTCP:LISTEN &>/dev/null }
docker_running() { docker ps --format '{{.Names}}' | grep -q "^$1$" }
docker_exists()  { docker ps -a --format '{{.Names}}' | grep -q "^$1$" }

# ════════════════════════════════════════════════════════
# 1. LM STUDIO — sprawdź czy działa
# ════════════════════════════════════════════════════════
if port_in_use $LM_STUDIO_PORT; then
  echo "✅ LM Studio działa na :${LM_STUDIO_PORT}"
else
  echo "⚠️  LM Studio nie działa na :${LM_STUDIO_PORT}"
  echo "   Uruchom LM Studio app i załaduj model"
  echo "   Potem uruchom lokalny serwer w LM Studio (Developer → Start Server)"
fi

# ════════════════════════════════════════════════════════
# 2. WHISPER (audio transcription)
# ════════════════════════════════════════════════════════
if port_in_use $WHISPER_PORT; then
  echo "✅ Whisper już działa na :${WHISPER_PORT}"
else
  echo "🎙️  Uruchamiam Whisper..."
  mlx-openai-server launch \
    --model-path "$WHISPER_PATH" \
    --model-type whisper \
    --port "$WHISPER_PORT" \
    --host 0.0.0.0 \
    > "$LOG_DIR/whisper.log" 2>&1 &
  sleep 5
  port_in_use $WHISPER_PORT \
    && echo "✅ Whisper gotowy na :${WHISPER_PORT}" \
    || echo "⚠️  Whisper nie uruchomił się. Sprawdź: tail -f $LOG_DIR/whisper.log"
fi

# ════════════════════════════════════════════════════════
# 3. SEARXNG (web search — Docker)
# ════════════════════════════════════════════════════════
if docker_running $SEARXNG_CONTAINER; then
  echo "✅ SearXNG już działa na :${SEARXNG_PORT}"
elif docker_exists $SEARXNG_CONTAINER; then
  echo "♻️  Restartuję SearXNG..."
  docker start "$SEARXNG_CONTAINER"
  echo "✅ SearXNG zrestartowany na :${SEARXNG_PORT}"
else
  echo "🔍 Uruchamiam SearXNG..."
  docker run -d \
    --name "$SEARXNG_CONTAINER" \
    -p "${SEARXNG_PORT}:8080" \
    --restart always \
    -v "${SEARXNG_CONFIG_DIR}:/etc/searxng:rw" \
    -e SEARXNG_BASE_URL="http://localhost:${SEARXNG_PORT}" \
    searxng/searxng:latest
  echo "✅ SearXNG uruchomiony na :${SEARXNG_PORT}"
fi

# ════════════════════════════════════════════════════════
# 4. TIKA OCR (scanned PDFs — Docker)
# ════════════════════════════════════════════════════════
if docker_running $TIKA_CONTAINER; then
  echo "✅ Tika już działa na :${TIKA_PORT}"
elif docker_exists $TIKA_CONTAINER; then
  echo "♻️  Restartuję Tika..."
  docker start "$TIKA_CONTAINER"
  echo "✅ Tika zrestartowany na :${TIKA_PORT}"
else
  echo "📄 Uruchamiam Tika OCR..."
  docker run -d \
    --name "$TIKA_CONTAINER" \
    -p "${TIKA_PORT}:9998" \
    --restart always \
    apache/tika:latest
  echo "✅ Tika uruchomiony na :${TIKA_PORT}"
fi

# ════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════
echo ""
echo "┌──────────────────────────────────────────────────────┐"
echo "│  🎯 LM Studio      http://localhost:${LM_STUDIO_PORT}          │"
echo "│  🎙️  Whisper        http://localhost:${WHISPER_PORT}          │"
echo "│  🔍 SearXNG        http://localhost:${SEARXNG_PORT}          │"
echo "│  📄 Tika OCR       http://localhost:${TIKA_PORT}          │"
echo "└──────────────────────────────────────────────────────┘"
echo ""
echo "  AnythingLLM → LM Studio: http://localhost:${LM_STUDIO_PORT}/v1"
echo "  SearXNG URL: http://localhost:${SEARXNG_PORT}/search?q=<query>&format=json"
echo "  Logi: tail -f $LOG_DIR/whisper.log"
echo "  Stop: ./stop.sh"