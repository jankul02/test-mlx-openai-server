#!/bin/zsh
# stop.sh - zatrzymuje wszystkie serwisy
# Reentrant: bezpieczne gdy serwisy już zatrzymane

source ./config.sh

port_in_use()    { lsof -i ":$1" -sTCP:LISTEN &>/dev/null }
docker_running() { docker ps --format '{{.Names}}' | grep -q "^$1$" }

stop_port() {
  local name="$1" port="$2"
  if port_in_use $port; then
    echo "🛑 Zatrzymuję $name..."
    lsof -ti ":${port}" | xargs kill -TERM 2>/dev/null
    sleep 2
    lsof -ti ":${port}" | xargs kill -9 2>/dev/null
    echo "✅ $name zatrzymany"
  else
    echo "✅ $name już zatrzymany"
  fi
}

stop_docker() {
  local name="$1"
  if docker_running "$name"; then
    echo "🛑 Zatrzymuję $name..."
    docker stop "$name"
    echo "✅ $name zatrzymany"
  else
    echo "✅ $name już zatrzymany"
  fi
}

# Zatrzymuj w odwrotnej kolejności niż start
stop_docker "$WEBUI_CONTAINER"
stop_port   "OpenClaw"      $OPENCLAW_PORT
stop_port   "Open Terminal" 57321
stop_docker "$TIKA_CONTAINER"
stop_docker "$SEARXNG_CONTAINER"
stop_port   "Whisper"       $WHISPER_PORT
stop_port   "Gemma 4"       $MODEL_PORT

echo ""
echo "✅ Wszystkie serwisy zatrzymane"
