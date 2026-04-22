#!/bin/zsh
# monitor.sh - live status and tok/s monitoring

source ./config.sh

port_in_use() { lsof -i ":$1" -sTCP:LISTEN &>/dev/null }

echo "📊 Monitor (Ctrl+C to stop)"
echo "   Tip: run a query in Open WebUI and watch tok/s appear in logs"
echo ""

while true; do
  clear

  # ── Status ─────────────────────────────────────────
  MLX_STATUS=$(port_in_use $MODEL_PORT && echo "🟢 running :${MODEL_PORT}" || echo "🔴 stopped")
  WHISPER_STATUS=$(port_in_use $WHISPER_PORT && echo "🟢 running :${WHISPER_PORT}" || echo "🔴 stopped")
  TIKA_STATUS=$(docker ps --format '{{.Names}}' | grep -q "^${TIKA_CONTAINER}$" && echo "🟢 running :${TIKA_PORT}" || echo "🔴 stopped")
  WEBUI_STATUS=$(docker ps --format '{{.Names}}' | grep -q "^${WEBUI_CONTAINER}$" && echo "🟢 running :${WEBUI_PORT}" || echo "🔴 stopped")

  # ── Memory ─────────────────────────────────────────
  MEM_GB=$(python3 -c "
import subprocess, re
out = subprocess.run(['vm_stat'], capture_output=True, text=True).stdout
page = 16384
free = int(re.search(r'Pages free:\s+(\d+)', out).group(1)) * page
used = 64*1024**3 - free
print(f'{used/1024**3:.1f}')
" 2>/dev/null || echo "?")

  # ── Last tok/s from log ────────────────────────────
  LAST_TOKS=$(grep -o "[0-9.]* tok/s" "$LOG_DIR/mlx-server.log" 2>/dev/null | tail -1 || echo "—")

  echo "┌─────────────────────────────────────────────────┐"
  printf "│  %-47s │\n" "$(date '+%H:%M:%S')  M1 Max 64GB"
  echo "├─────────────────────────────────────────────────┤"
  printf "│  MLX server   %-33s │\n" "$MLX_STATUS"
  printf "│  Whisper      %-33s │\n" "$WHISPER_STATUS"
  printf "│  Tika         %-33s │\n" "$TIKA_STATUS"
  printf "│  Open WebUI   %-33s │\n" "$WEBUI_STATUS"
  echo "├─────────────────────────────────────────────────┤"
  printf "│  Memory used: %-32s │\n" "${MEM_GB} GB"
  printf "│  Last tok/s:  %-32s │\n" "$LAST_TOKS"
  echo "└─────────────────────────────────────────────────┘"
  echo ""
  echo "  Logs:"
  echo "  tail -f $LOG_DIR/mlx-server.log | grep tok"

  sleep 4
done
