#!/bin/zsh
# status.sh - status wszystkich serwisów

source ./config.sh

port_in_use()    { lsof -i ":$1" -sTCP:LISTEN &>/dev/null }
docker_running() { docker ps --format '{{.Names}}' | grep -q "^$1$" }

ok()   { echo "  🟢 $1" }
fail() { echo "  🔴 $1" }
warn() { echo "  🟡 $1" }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Status serwisów — $(date '+%H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# LM Studio — uruchamiane ręcznie
if port_in_use $LM_STUDIO_PORT; then
  ok "LM Studio        :${LM_STUDIO_PORT}"
else
  warn "LM Studio        :${LM_STUDIO_PORT}  ← uruchom app ręcznie"
fi

port_in_use $WHISPER_PORT          && ok "Whisper          :${WHISPER_PORT}" || fail "Whisper          :${WHISPER_PORT}"
docker_running $SEARXNG_CONTAINER  && ok "SearXNG          :${SEARXNG_PORT}" || fail "SearXNG          :${SEARXNG_PORT}"
docker_running $TIKA_CONTAINER     && ok "Tika OCR         :${TIKA_PORT}" || fail "Tika OCR         :${TIKA_PORT}"

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
echo ""

echo "  AnythingLLM → http://localhost:${LM_STUDIO_PORT}/v1"
echo "  SearXNG     → http://localhost:${SEARXNG_PORT}/search?q=<query>&format=json"