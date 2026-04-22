#!/bin/zsh
# status.sh - szybki przegląd statusu wszystkich serwisów

source ./config.sh

port_in_use()    { lsof -i ":$1" -sTCP:LISTEN &>/dev/null }
docker_running() { docker ps --format '{{.Names}}' | grep -q "^$1$" }

ok()   { echo "  🟢 $1" }
fail() { echo "  🔴 $1" }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Status serwisów — $(date '+%H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

port_in_use $MODEL_PORT    && ok "Gemma 4 Vision  :${MODEL_PORT}"   || fail "Gemma 4 Vision  :${MODEL_PORT}"
port_in_use $WHISPER_PORT  && ok "Whisper         :${WHISPER_PORT}"   || fail "Whisper         :${WHISPER_PORT}"
docker_running $SEARXNG_CONTAINER && ok "SearXNG         :${SEARXNG_PORT}" || fail "SearXNG         :${SEARXNG_PORT}"
docker_running $TIKA_CONTAINER    && ok "Tika OCR        :${TIKA_PORT}" || fail "Tika OCR        :${TIKA_PORT}"
port_in_use 57321          && ok "Open Terminal   :57321"             || fail "Open Terminal   :57321"
port_in_use $OPENCLAW_PORT && ok "OpenClaw        :${OPENCLAW_PORT}" || fail "OpenClaw        :${OPENCLAW_PORT}"
docker_running $WEBUI_CONTAINER   && ok "Open WebUI      :${WEBUI_PORT}" || fail "Open WebUI      :${WEBUI_PORT}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Pamięć
MEM_USED=$(python3 -c "
import subprocess, re
out = subprocess.run(['vm_stat'], capture_output=True, text=True).stdout
m = re.search(r'Pages free:\s+(\d+)', out)
free_gb = int(m.group(1)) * 16384 / 1024**3 if m else 0
print(f'{64 - free_gb:.1f}')
" 2>/dev/null || echo "?")
echo "  💾 Pamięć: ~${MEM_USED} GB / 64 GB"

# Ostatni tok/s z loga
LAST_TOKS=$(grep -o "[0-9.]* tok/s" "$LOG_DIR/gemma.log" 2>/dev/null | tail -1)
[[ -n "$LAST_TOKS" ]] && echo "  ⚡ Ostatnia prędkość: $LAST_TOKS"

echo ""
