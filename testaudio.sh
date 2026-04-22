#!/bin/zsh
# testaudio.sh - test Whisper audio transcription
# Usage: ./testaudio.sh [path/to/audio.mp3]

source ./config.sh

AUDIO_FILE="${1:-/tmp/test_audio.mp3}"

if [[ ! -f "$AUDIO_FILE" ]]; then
  echo "📥 Downloading test audio..."
  curl -s -o /tmp/test_audio.mp3 \
    "https://www.w3schools.com/html/horse.mp3"
  AUDIO_FILE="/tmp/test_audio.mp3"
fi

echo "🎙️  Testing Whisper on :${WHISPER_PORT}..."
echo "   File: $AUDIO_FILE"

source "$VENV_DIR/bin/activate"

python3 -c "
import json, urllib.request, sys

port = $WHISPER_PORT

# Check server
try:
    urllib.request.urlopen('http://localhost:{}/v1/models'.format(port), timeout=5)
except:
    print(f'❌ Whisper server not running on :{port}')
    sys.exit(1)

import urllib.parse

with open('$AUDIO_FILE', 'rb') as f:
    audio_data = f.read()

boundary = 'boundary123'
body = (
    f'--{boundary}\r\n'
    f'Content-Disposition: form-data; name=\"file\"; filename=\"audio.mp3\"\r\n'
    f'Content-Type: audio/mpeg\r\n\r\n'
).encode() + audio_data + f'\r\n--{boundary}--\r\n'.encode()

req = urllib.request.Request(
    f'http://localhost:{port}/v1/audio/transcriptions',
    data=body,
    headers={'Content-Type': f'multipart/form-data; boundary={boundary}'}
)

try:
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.loads(r.read().decode())
        print('✅ Transcription:')
        print(data.get('text', data))
except urllib.error.HTTPError as e:
    print(f'❌ HTTP {e.code}: {e.reason}')
    print(e.read().decode())
    sys.exit(1)
except Exception as e:
    print(f'❌ Error: {e}')
    sys.exit(1)
"
