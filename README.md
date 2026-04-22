# test-mlx-openai-server

MLX-native AI stack na Apple Silicon — szybszy niż Ollama, z vision, Whisper i RAG.

**Stack:** mlx-openai-server · Gemma 4 26B · Whisper large-v3 · Tika OCR · Open WebUI  
**Hardware:** MacBook Pro M1 Max 64 GB

---

## Architektura

```
Mac (natywnie, Metal GPU)
┌────────────────────────────────────────────┐
│  mlx-openai-server                         │
│  Gemma 4 26B 6bit  :8090  vision ✅        │
│  Whisper large-v3  :8091  audio ✅         │
└───────────┬────────────────────────────────┘
            │ HTTP
Docker      │
┌───────────▼────────────────────────────────┐
│  Open WebUI        :3000                   │
│  PDF/Word/Excel/PowerPoint ✅              │
│  Tika OCR (skany) :9998   ✅              │
└────────────────────────────────────────────┘
```

mlx-openai-server rozwiązuje problem wątkowania MLX przez izolację procesów (`spawn`),  
której brakowało w rapid-mlx. Każdy model działa w osobnym podprocesie z czystym Metal context.

---

## Wymagania

- macOS Apple Silicon (M1+)
- Python 3.11 (instaluje `setup.sh`)
- Docker Desktop
- Homebrew

---

## Szybki start

```bash
# 1. Sklonuj
git clone https://github.com/jankul02/test-mlx-openai-server.git
cd test-mlx-openai-server

# 2. Instalacja (~20 GB pobierania modeli)
./setup.sh

# 3. Uruchom wszystko
./start.sh

# 4. Otwórz przeglądarkę
open http://localhost:3000
```

---

## Skrypty

| Skrypt | Opis |
|---|---|
| `config.sh` | Wspólna konfiguracja — modele, porty. Tu zmieniasz model. |
| `setup.sh` | Jednorazowa instalacja. Bezpieczne do wielokrotnego uruchomienia. |
| `start.sh` | Start wszystkich serwisów. **Reentrant** — bezpieczne gdy już działa. |
| `stop.sh` | Stop wszystkich serwisów. **Reentrant** — bezpieczne gdy już zatrzymane. |
| `testimage.sh` | Test vision — wysyła obraz do modelu. |
| `testaudio.sh` | Test Whisper — transkrypcja audio. Użycie: `./testaudio.sh plik.mp3` |
| `monitor.sh` | Live monitoring: status serwisów, tok/s, zużycie pamięci. |
| `clean.sh` | Usuwa venv, logi, pliki tymczasowe. |

---

## Konfiguracja (`config.sh`)

```zsh
MODEL_PATH="mlx-community/gemma-4-26b-a4b-it-6bit"
MODEL_TYPE="multimodal"    # multimodal = vision przez mlx-vlm
MODEL_PORT=8090

WHISPER_PATH="mlx-community/whisper-large-v3-mlx"
WHISPER_PORT=8091

WEBUI_PORT=3000
TIKA_PORT=9998
```

---

## Model

**Gemma 4 26B MoE · 6-bit**

| Właściwość | Wartość |
|---|---|
| Rozmiar modelu | ~20 GB |
| Aktywne parametry | 3.8B (MoE — szybki!) |
| Kontekst | 256K tokenów |
| Vision | ✅ obrazy w chacie |
| Języki | 140+ |

MoE (Mixture of Experts) aktywuje tylko 3.8B z 26B parametrów podczas generowania —  
co oznacza prędkość porównywalną z modelem 4B przy jakości modelu 26B.

---

## Obsługiwane formaty plików

| Format | Jak działa |
|---|---|
| PDF (tekstowy) | Tekst wyciągany przez Open WebUI → model |
| PDF (skan/obraz) | OCR przez Tika → tekst → model |
| Word (.docx/.doc) | Tekst wyciągany |
| Excel (.xlsx/.xls) | Komórki wyciągane |
| PowerPoint (.pptx/.ppt) | Tekst ze slajdów |
| Obrazy (jpg/png) | Wysyłane bezpośrednio do Gemma 4 vision |
| Audio (mp3/wav/m4a) | Transkrypcja przez Whisper → tekst → model |
| URL | Treść strony pobierana i indeksowana |

---

## Serwisy

| Serwis | URL | Opis |
|---|---|---|
| Open WebUI | http://localhost:3000 | Interfejs czatu |
| MLX server | http://localhost:8090 | Inference modelu |
| Whisper | http://localhost:8091 | Transkrypcja audio |
| Tika OCR | http://localhost:9998 | OCR skanów |

---

## Przydatne komendy

```bash
# Logi na żywo
tail -f logs/mlx-server.log          # główny serwer
tail -f logs/whisper.log             # Whisper
docker logs -f open-webui-mlx        # Open WebUI

# Szybki test tekstowy
curl http://localhost:8090/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"mlx-community/gemma-4-26b-a4b-it-6bit",
       "messages":[{"role":"user","content":"cześć"}]}'

# Test vision
./testimage.sh

# Test audio (Whisper)
./testaudio.sh nagranie.mp3

# Test Tika OCR
curl -T dokument.pdf http://localhost:9998/tika --header "Accept: text/plain"

# Monitoring na żywo
./monitor.sh

# Pełny restart
./stop.sh && ./start.sh
```

---

## Dlaczego mlx-openai-server zamiast rapid-mlx

rapid-mlx używał `asyncio.to_thread()` do obsługi żądań — wątki z puli nie mają Metal GPU stream,  
co powoduje crash `RuntimeError: There is no Stream(gpu, 1) in current thread`.

mlx-openai-server uruchamia każdy model w osobnym podprocesie przez `multiprocessing.spawn`,  
dając każdemu czysty Metal context. To poprawne rozwiązanie otwartego bugu Apple (#2133 w ml-explore/mlx).

---

## Usuwanie wszystkiego

```bash
./stop.sh

# Kontenery i dane czatu
docker rm -f open-webui-mlx tika
docker volume rm open-webui-mlx

# Cache modeli (~23 GB)
rm -rf ~/.cache/huggingface/hub/models--mlx-community--gemma-4-26b-a4b-it-6bit
rm -rf ~/.cache/huggingface/hub/models--mlx-community--whisper-large-v3-mlx

# venv i logi
./clean.sh
```
