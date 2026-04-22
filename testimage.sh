#!/bin/zsh
# testimage.sh - test vision (mlx_vlm.server)

source ./config.sh
source "$VENV_DIR/bin/activate"

IMG_FILE="/tmp/test_vision.png"

echo "📥 Pobieranie obrazu testowego..."
curl -s -L -A "Mozilla/5.0" \
  -o "$IMG_FILE" \
  "https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png"

echo "   Rozmiar: $(wc -c < $IMG_FILE | tr -d ' ') bajtów"
echo "🔍 Test vision: $MODEL_PATH na :${MODEL_PORT}..."

python3 - <<PYEOF
import json, urllib.request, sys, base64

port  = ${MODEL_PORT}
model = "${MODEL_PATH}"

with open("${IMG_FILE}", "rb") as f:
    b64 = base64.b64encode(f.read()).decode()

payload = {
    "model": model,
    "messages": [{
        "role": "user",
        "content": [
            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}"}},
            {"type": "text", "text": "What is in this image? Describe it."}
        ]
    }],
    "stream": False,
    "max_tokens": 300
}

req = urllib.request.Request(
    f"http://localhost:{port}/v1/chat/completions",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"}
)

try:
    with urllib.request.urlopen(req, timeout=120) as r:
        data = json.loads(r.read().decode())
        print("✅ Odpowiedź:")
        print(data["choices"][0]["message"]["content"])
except urllib.error.HTTPError as e:
    print(f"❌ HTTP {e.code}: {e.reason}")
    print(e.read().decode())
    sys.exit(1)
except Exception as e:
    print(f"❌ Błąd: {e}")
    sys.exit(1)
PYEOF
