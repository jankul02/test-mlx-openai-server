#!/bin/zsh
# start.sh - uruchamia wszystkie serwisy (Gemma-4 Vision + Whisper + SearXNG + Tika + Open WebUI + OpenClaw)
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
# 1. GEMMA 4 VISION (mlx_vlm.server)
# ════════════════════════════════════════════════════════
if port_in_use $MODEL_PORT; then
  echo "✅ Gemma 4 Vision już działa na :${MODEL_PORT}"
else
  echo "🚀 Uruchamiam Gemma 4 Vision (6-bit)..."
  echo "   Model: $MODEL_PATH"

  mlx_vlm.server \
    --model "$MODEL_PATH" \
    --port "$MODEL_PORT" \
    --host 0.0.0.0 \
    --max-kv-size 32768 \
    > "$LOG_DIR/gemma.log" 2>&1 &

  echo -n "   Czekam na gotowość"
  for i in {1..60}; do
    curl -s "http://localhost:${MODEL_PORT}/v1/models" &>/dev/null && break
    echo -n "."
    sleep 2
  done
  echo ""

  if port_in_use $MODEL_PORT; then
    echo "✅ Gemma 4 Vision gotowa na :${MODEL_PORT}"
  else
    echo "❌ Gemma 4 nie uruchomiła się. Sprawdź: tail -f $LOG_DIR/gemma.log"
    exit 1
  fi
fi

# ════════════════════════════════════════════════════════
# 2. WHISPER
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
# 3. SEARXNG
# ════════════════════════════════════════════════════════
if docker_running $SEARXNG_CONTAINER; then
  echo "✅ SearXNG już działa na :${SEARXNG_PORT}"
elif docker_exists $SEARXNG_CONTAINER; then
  echo "♻️  Restartuję SearXNG..."
  docker start "$SEARXNG_CONTAINER"
  echo "✅ SearXNG zrestartowany na :${SEARXNG_PORT}"
else
  echo "🔍 Uruchamiam SearXNG..."
  mkdir -p "$SEARXNG_CONFIG_DIR"
  docker run -d \
    --name "$SEARXNG_CONTAINER" \
    -v "${SEARXNG_CONFIG_DIR}:/etc/searxng:rw" \
    -p "${SEARXNG_PORT}:8080" \
    --restart always \
    -e SEARXNG_BASE_URL="http://localhost:${SEARXNG_PORT}" \
    searxng/searxng:latest
  echo "✅ SearXNG uruchomiony na :${SEARXNG_PORT}"
fi

# ════════════════════════════════════════════════════════
# 4. TIKA OCR
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
# 5. OPEN TERMINAL
# ════════════════════════════════════════════════════════
if port_in_use 57321; then
  echo "✅ Open Terminal już działa na :57321"
else
  echo "🖥️  Uruchamiam Open Terminal..."
  .venv/bin/open-terminal run \
    --port 57321 \
    --cwd "$PROJECTS_DIR" \
    --host 127.0.0.1 \
    --api-key "$OPEN_TERMINAL_API_KEY" \
    > "$LOG_DIR/terminal.log" 2>&1 &
  sleep 3
  port_in_use 57321 \
    && echo "✅ Open Terminal gotowy na :57321 (root: $PROJECTS_DIR)" \
    || echo "⚠️  Open Terminal nie uruchomił się. Sprawdź: tail -f $LOG_DIR/terminal.log"
fi

# ════════════════════════════════════════════════════════
# 6. OPENCLAW (autonomiczny agent)
# ════════════════════════════════════════════════════════
if port_in_use $OPENCLAW_PORT; then
  echo "✅ OpenClaw już działa na :${OPENCLAW_PORT}"
elif command -v openclaw &>/dev/null; then
  echo "🦞 Uruchamiam OpenClaw (gateway)..."
  echo "   Port: $OPENCLAW_PORT"

#  openclaw gateway --port $OPENCLAW_PORT \
#    > "$LOG_DIR/openclaw.log" 2>&1 &


# Wewnątrz start.sh znajdź linię z openclaw i zmień ją na:
export OPENAI_API_KEY="local-none"
export OPENAI_BASE_URL="http://127.0.0"
export OPENAI_API_BASE="http://127.0.0"

openclaw gateway --port 18789 > ./logs/openclaw.log 2>&1 &


  sleep 8

  if port_in_use $OPENCLAW_PORT; then
    echo "✅ OpenClaw gotowy na :${OPENCLAW_PORT}"
  else
    echo "❌ OpenClaw nie uruchomił się!"
    echo "   Logi: tail -f $LOG_DIR/openclaw.log"
    echo "   Najczęstsze przyczyny:"
    echo "     • Nie wykonano onboardingu (openclaw onboard)"
    echo "     • Brak klucza API (odkomentuj OPENCLAW_API_KEY w config.sh)"
  fi
else
  echo "⚠️  OpenClaw nie jest zainstalowany (komenda 'openclaw' nie znaleziona)"
fi

# ════════════════════════════════════════════════════════
# 7. OPEN WEBUI
# ════════════════════════════════════════════════════════
if docker_running $WEBUI_CONTAINER; then
  echo "✅ Open WebUI już działa na :${WEBUI_PORT}"
elif docker_exists $WEBUI_CONTAINER; then
  echo "♻️  Restartuję Open WebUI..."
  docker start "$WEBUI_CONTAINER"
  echo "✅ Open WebUI zrestartowany na :${WEBUI_PORT}"
else
  echo "🐳 Uruchamiam Open WebUI..."
  docker run -d \
    -p "${WEBUI_PORT}:8080" \
    --add-host=host.docker.internal:host-gateway \
    -e ENABLE_OLLAMA_API=True \
    -e OLLAMA_BASE_URL="" \
    -e OPENAI_API_BASE_URL="http://host.docker.internal:${MODEL_PORT}/v1" \
    -e OPENAI_API_KEY=not-needed \
    -e CONTENT_EXTRACTION_ENGINE=tika \
    -e TIKA_SERVER_URL="http://host.docker.internal:${TIKA_PORT}" \
    -e WEBUI_WEB_SEARCH_ENGINE=searxng \
    -e SEARXNG_QUERY_URL="http://host.docker.internal:${SEARXNG_PORT}/search?q=<query>&format=json" \
    -v open-webui-mlx:/app/backend/data \
    -v "${PROJECTS_DIR}:/app/backend/data/projects:ro" \
    --name "$WEBUI_CONTAINER" \
    --restart always \
    ghcr.io/open-webui/open-webui:main
  echo "✅ Open WebUI uruchomiony na :${WEBUI_PORT}"
fi

# ════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════
echo ""
echo "┌──────────────────────────────────────────────────────┐"
echo "│  🌐 Open WebUI     http://localhost:${WEBUI_PORT}           │"
echo "│  👁️  Gemma 4 Vision http://localhost:${MODEL_PORT}          │"
echo "│  🎙️  Whisper        http://localhost:${WHISPER_PORT}          │"
echo "│  🔍 SearXNG        http://localhost:${SEARXNG_PORT}          │"
echo "│  📄 Tika OCR       http://localhost:${TIKA_PORT}          │"
echo "│  🖥️  Open Terminal  http://localhost:57321             │"
echo "│  🦞 OpenClaw       http://localhost:${OPENCLAW_PORT}        │"
echo "└──────────────────────────────────────────────────────┘"
echo ""
echo "  Logi Gemma:   tail -f $LOG_DIR/gemma.log"
echo "  Logi OpenClaw: tail -f $LOG_DIR/openclaw.log"
echo "  Stop: ./stop.sh"