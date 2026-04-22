#!/bin/zsh
# testaudio.sh - test transkrypcji audio (Whisper)
# Użycie: ./testaudio.sh [plik.mp3]

source ./config.sh
source "$VENV_DIR/bin/activate"

AUDIO_FILE="${1:-/tmp/test_audio.mp3}"

if [[ ! -f "$AUDIO_FILE" ]]; then
  echo "📥 Pobieranie testowego pliku audio..."
  curl -s -o /tmp/test_audio.mp3 "https://www.w3schools.com/html/horse.mp3"
  AUDIO_FILE="/tmp/test_audio.mp3"
fi

echo "🎙️  Test Whisper: $AUDIO_FILE na :${WHISPER_PORT}..."

python3 - <<PYEOF
import json, urllib.request, sys

port = ${WHISPER_PORT}

try:
    urllib.request.urlopen(f"http://localhost:{port}/v1/models", timeout=5)
except:
    print(f"❌ Whisper nie działa na :{port} — uruchom ./start.sh")
    sys.exit(1)

boundary = "whisper_boundary_123"
with open("${AUDIO_FILE}", "rb") as f:
    audio_data = f.read()

body = (
    f"--{boundary}\r\n"
    f'Content-Disposition: form-data; name="file"; filename="audio.mp3"\r\n'
    f"Content-Type: audio/mpeg\r\n\r\n"
).encode() + audio_data + f"\r\n--{boundary}--\r\n".encode()

req = urllib.request.Request(
    f"http://localhost:{port}/v1/audio/transcriptions",
    data=body,
    headers={"Content-Type": f"multipart/form-data; boundary={boundary}"}
)

try:
    with urllib.request.urlopen(req, timeout=120) as r:
        data = json.loads(r.read().decode())
        print("✅ Transkrypcja:")
        print(data.get("text", str(data)))
except urllib.error.HTTPError as e:
    print(f"❌ HTTP {e.code}: {e.reason}")
    print(e.read().decode())
    sys.exit(1)
PYEOF
