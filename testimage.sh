#!/bin/zsh
source ./config.sh
source "$VENV_DIR/bin/activate"

IMG_FILE="/tmp/test_vision.png"

echo "📥 Downloading test image..."
curl -s -L -A "Mozilla/5.0" \
  -o "$IMG_FILE" \
  "https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png"

echo "   Size: $(wc -c < $IMG_FILE) bytes"

echo "🔍 Testing vision on :${MODEL_PORT}..."

python3 - << PYEOF
import json, urllib.request, sys, base64

port  = ${MODEL_PORT}
model = "${MODEL_PATH}"

with open("${IMG_FILE}", "rb") as f:
    raw = f.read()

print(f"   Image bytes: {len(raw)}")

b64 = base64.b64encode(raw).decode()
data_url = f"data:image/png;base64,{b64}"

payload = {
    "model": model,
    "messages": [{
        "role": "user",
        "content": [
            {"type": "image_url", "image_url": {"url": data_url}},
            {"type": "text", "text": "What is in this image?"}
        ]
    }],
    "stream": False,
    "max_tokens": 200
}

req = urllib.request.Request(
    f"http://localhost:{port}/v1/chat/completions",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"}
)

try:
    with urllib.request.urlopen(req, timeout=120) as r:
        data = json.loads(r.read().decode())
        print("✅ Response:")
        print(data["choices"][0]["message"]["content"])
except urllib.error.HTTPError as e:
    print(f"❌ HTTP {e.code}")
    print(e.read().decode())
    sys.exit(1)
PYEOF
