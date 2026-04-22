#!/bin/zsh
# start.sh - start mlx_vlm.server (Gemma-4 Vision 6-bit) + Whisper + Tika + Open WebUI
# Reentrant: safe to run if any or all services are already running

source ./config.sh
mkdir -p "$LOG_DIR"

# ── Helper: is port in use? ──────────────────────────────
port_in_use() { lsof -i ":$1" -sTCP:LISTEN &>/dev/null }

# ── Activate venv ────────────────────────────────────────
if [[ ! -d "$VENV_DIR" ]]; then
  echo "❌ venv not found. Run ./setup.sh first."
  exit 1
fi
source "$VENV_DIR/bin/activate"

# ── mlx_vlm.server (Gemma-4 Vision 6-bit) ───────────────
if port_in_use $MODEL_PORT; then
  echo "✅ mlx_vlm.server already running on :${MODEL_PORT}"
else
  echo "🚀 Starting mlx_vlm.server (Gemma-4 Vision)..."
  echo "   Model: $MODEL_PATH"
  echo "   (6-bit – optimized for M1 Max 64 GB)"

  mlx_vlm.server \
      --model "$MODEL_PATH" \
      --port "$MODEL_PORT" \
      --host 0.0.0.0 \
      > "$LOG_DIR/mlx-server.log" 2>&1 &

  echo -n "   Waiting for model server"
  for i in {1..60}; do
    if curl -s "http://localhost:${MODEL_PORT}/v1/models" &>/dev/null; then
      echo " ready"
      break
    fi
    echo -n "."
    sleep 2
  done

  if ! port_in_use $MODEL_PORT; then
    echo ""
    echo "❌ mlx_vlm.server failed to start."
    echo "   Check: tail -f $LOG_DIR/mlx-server.log"
    exit 1
  fi
  echo "✅ mlx_vlm.server ready on :${MODEL_PORT}"
fi

# ── Whisper server (mlx-openai-server) ───────────────────
if port_in_use $WHISPER_PORT; then
  echo "✅ Whisper already running on :${WHISPER_PORT}"
else
  echo "🎙️  Starting Whisper (audio transcription)..."
  mlx-openai-server launch \
    --model-path "$WHISPER_PATH" \
    --model-type whisper \
    --port "$WHISPER_PORT" \
    --host 0.0.0.0 \
    > "$LOG_DIR/whisper.log" 2>&1 &

  sleep 5
  if port_in_use $WHISPER_PORT; then
    echo "✅ Whisper ready on :${WHISPER_PORT}"
  else
    echo "⚠️  Whisper failed to start (non-critical)"
    echo "   Check: tail -f $LOG_DIR/whisper.log"
  fi
fi

# ── Tika OCR ─────────────────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q "^${TIKA_CONTAINER}$"; then
  echo "✅ Tika already running on :${TIKA_PORT}"
elif docker ps -a --format '{{.Names}}' | grep -q "^${TIKA_CONTAINER}$"; then
  echo "♻️  Restarting Tika..."
  docker start "$TIKA_CONTAINER"
  echo "✅ Tika restarted on :${TIKA_PORT}"
else
  echo "🐳 Starting Tika (OCR for scanned PDFs)..."
  docker run -d \
    --name "$TIKA_CONTAINER" \
    -p "${TIKA_PORT}:9998" \
    --restart always \
    apache/tika:latest
  echo "✅ Tika started on :${TIKA_PORT}"
fi

# ── Open WebUI ───────────────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q "^${WEBUI_CONTAINER}$"; then
  echo "✅ Open WebUI already running on :${WEBUI_PORT}"
elif docker ps -a --format '{{.Names}}' | grep -q "^${WEBUI_CONTAINER}$"; then
  echo "♻️  Restarting Open WebUI..."
  docker start "$WEBUI_CONTAINER"
  echo "✅ Open WebUI restarted on :${WEBUI_PORT}"
else
  echo "🐳 Starting Open WebUI..."
  docker run -d \
    -p "${WEBUI_PORT}:8080" \
    --add-host=host.docker.internal:host-gateway \
    -e ENABLE_OLLAMA_API=False \
    -e OPENAI_API_BASE_URL="http://host.docker.internal:${MODEL_PORT}/v1" \
    -e OPENAI_API_KEY=not-needed \
    -e CONTENT_EXTRACTION_ENGINE=tika \
    -e TIKA_SERVER_URL="http://host.docker.internal:${TIKA_PORT}" \
    -v open-webui-mlx:/app/backend/data \
    --name "$WEBUI_CONTAINER" \
    --restart always \
    ghcr.io/open-webui/open-webui:main
  echo "✅ Open WebUI started on :${WEBUI_PORT}"
fi

# ── Summary ──────────────────────────────────────────────
echo ""
echo "┌──────────────────────────────────────────────────┐"
echo "│  🌐 Open WebUI    http://localhost:${WEBUI_PORT}         │"
echo "│  🤖 Gemma-4 Vision http://localhost:${MODEL_PORT}        │"
echo "│  🎙️  Whisper       http://localhost:${WHISPER_PORT}        │"
echo "│  📄 Tika OCR      http://localhost:${TIKA_PORT}        │"
echo "└──────────────────────────────────────────────────┘"
echo ""
echo "  Logs: tail -f $LOG_DIR/mlx-server.log"