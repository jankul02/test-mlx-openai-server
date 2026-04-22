#!/bin/zsh
# testimage.sh - test vision capability via mlx-openai-server

source ./config.sh

IMG_URL="https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/280px-PNG_transparency_demonstration_1.png"

echo "📥 Downloading test image..."
curl -s -o /tmp/test.png "$IMG_URL"

echo "🔍 Testing vision: $MODEL_PATH on :${MODEL_PORT}..."

python3 -c "
import base64, json, urllib.request, sys

port = $MODEL_PORT

with open('/tmp/test.png', 'rb') as f:
    b64 = base64.b64encode(f.read()).decode()

# Get actual model name from server
try:
    with urllib.request.urlopen('http://localhost:{}/v1/models'.format(port), timeout=5) as r:
        models = json.loads(r.read().decode())
        model = models['data'][0]['id']
        print(f'   Model: {model}')
except Exception as e:
    print(f'❌ Cannot reach server on :{port} — is ./start.sh running?')
    sys.exit(1)

payload = {
    'model': model,
    'messages': [{
        'role': 'user',
        'content': [
            {'type': 'text', 'text': 'What is in this image? Describe it in detail.'},
            {'type': 'image_url', 'image_url': {'url': f'data:image/png;base64,{b64}'}}
        ]
    }],
    'stream': False
}

req = urllib.request.Request(
    f'http://localhost:{port}/v1/chat/completions',
    data=json.dumps(payload).encode(),
    headers={'Content-Type': 'application/json'}
)

try:
    with urllib.request.urlopen(req, timeout=120) as r:
        data = json.loads(r.read().decode())
        print('✅ Response:')
        print(data['choices'][0]['message']['content'])
except urllib.error.HTTPError as e:
    print(f'❌ HTTP {e.code}: {e.reason}')
    print(e.read().decode())
    sys.exit(1)
except Exception as e:
    print(f'❌ Error: {e}')
    sys.exit(1)
"
