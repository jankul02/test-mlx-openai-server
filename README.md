# test-mlx-openai-server

MLX-native AI stack na Apple Silicon — szybki, lokalny, prywatny.

**Hardware:** MacBook Pro M1 Max 64 GB  
**Model:** Gemma 4 26B MoE · 6-bit · vision ✅ · 256K kontekst

---

## Architektura

```
Mac (natywnie, Metal GPU)
┌─────────────────────────────────────────────┐
│  mlx_vlm.server    :8090   Gemma 4 Vision   │
│  mlx-openai-server :8091   Whisper STT      │
│  open-terminal     :57321  dostęp do plików │
│  openclaw          :18789  agent autonomiczny│
└──────────────┬──────────────────────────────┘
               │ HTTP
Docker         │
┌──────────────▼──────────────────────────────┐
│  Open WebUI   :3000   interfejs czatu        │
│  SearXNG      :8888   web search            │
│  Tika OCR     :9998   skany PDF             │
└─────────────────────────────────────────────┘
```

---

## Szybki start

```bash
git clone https://github.com/jankul02/test-mlx-openai-server.git
cd test-mlx-openai-server

./setup.sh          # instalacja (~23 GB modeli)
openclaw onboard    # konfiguracja agenta (jednorazowo)
# wpisz OPENCLAW_API_KEY w config.sh

./start.sh          # uruchom wszystko
open http://localhost:3000
```

---

## Skrypty

| Skrypt | Opis |
|---|---|
| `config.sh` | Konfiguracja — modele, porty. **Jedyne miejsce do zmian.** |
| `setup.sh` | Instalacja zależności. Bezpieczne do wielokrotnego uruchomienia. |
| `start.sh` | Start wszystkich serwisów. **Reentrant.** |
| `stop.sh` | Stop wszystkich serwisów. **Reentrant.** |
| `status.sh` | Szybki przegląd co działa + pamięć + tok/s. |
| `testimage.sh` | Test vision — wysyła obraz do Gemma 4. |
| `testaudio.sh` | Test Whisper. Użycie: `./testaudio.sh plik.mp3` |
| `clean.sh` | Usuwa venv, logi, pliki tymczasowe. |

---

## Serwisy

| Serwis | URL | Opis |
|---|---|---|
| Open WebUI | http://localhost:3000 | Główny interfejs czatu |
| Gemma 4 Vision | http://localhost:8090 | Inference + vision |
| Whisper | http://localhost:8091 | Transkrypcja audio |
| SearXNG | http://localhost:8888 | Web search (prywatny) |
| Tika OCR | http://localhost:9998 | OCR skanowanych PDF |
| Open Terminal | http://localhost:57321 | Przeglądanie plików z chatu |
| OpenClaw | http://localhost:18789 | Autonomiczny agent |

---

## Model

**Gemma 4 26B A4B MoE · 6-bit**

| | |
|---|---|
| Rozmiar | ~20 GB |
| Aktywne parametry | 3.8B (MoE = prędkość 4B, jakość 26B) |
| Kontekst | 256K tokenów |
| Vision | ✅ obrazy bezpośrednio w chacie |
| Języki | 140+ |

---

## Obsługiwane formaty plików

| Format | Jak działa |
|---|---|
| PDF (tekstowy) | Tekst → model |
| PDF (skan) | OCR Tika → tekst → model |
| Word (.docx/.doc) | Tekst → model |
| Excel (.xlsx/.xls) | Komórki → model |
| PowerPoint (.pptx) | Tekst slajdów → model |
| Obrazy (jpg/png) | Bezpośrednio do Gemma 4 vision |
| Audio (mp3/wav/m4a) | Whisper → transkrypcja → model |
| URL | Treść strony → model |

---

## OpenClaw — autonomiczny agent

OpenClaw podłączony do Open WebUI jako dodatkowy model:

```
Admin Settings → Connections → OpenAI → + Add
URL:     http://localhost:18789/v1
API Key: [OPENCLAW_API_KEY z config.sh]
```

Przykładowe komendy w chacie (wybierz model "openclaw"):

```
"Sprawdź folder ~/projects/klient-abc/input/ i wypisz dokumenty"
"Nowa wersja requirements jest w Downloads. Zastąp v1 w projekcie ABC."
"Stwórz strukturę folderów dla nowego projektu XYZ"
"Wyszukaj w internecie aktualną wersję specyfikacji OAuth 2.1"
```

Skills do zainstalowania:
```bash
openclaw skills install gtrusler/clawdbot-filesystem  # operacje na plikach
openclaw skills install steipete/github               # Git/GitHub
openclaw skills install obsidian                      # notatki Obsidian
```

---

## Konfiguracja Open WebUI po pierwszym uruchomieniu

**Web Search:**
```
Admin Panel → Settings → Web Search
Engine: SearXNG
URL: http://host.docker.internal:8888/search?q=<query>&format=json
```

**Embedding model (lepszy RAG):**
```
Admin Panel → Settings → Documents → Embedding Model
sentence-transformers/all-MiniLM-L6-v2
```

**RAG chunk size (dla dokumentów technicznych):**
```
Chunk Size: 800
Chunk Overlap: 150
Top K: 6
```

---

## Przydatne komendy

```bash
# Status wszystkich serwisów
./status.sh

# Logi na żywo
tail -f logs/gemma.log
tail -f logs/whisper.log
tail -f logs/openclaw.log
docker logs -f open-webui-mlx

# Pełny restart
./stop.sh && ./start.sh

# Test vision
./testimage.sh

# Test audio
./testaudio.sh ~/nagranie.mp3

# Test Tika OCR
curl -T dokument.pdf http://localhost:9998/tika --header "Accept: text/plain"
```

---

## Dlaczego mlx_vlm.server zamiast mlx-openai-server dla vision

`mlx-openai-server` z `--model-type multimodal` crashuje z `Stream(gpu, 0) in current thread` — ten sam bug MLX co w rapid-mlx (asyncio threading).

`mlx_vlm.server` uruchamia inference na głównym wątku — brak problemu z Metal GPU stream. Vision działa stabilnie.

Szczegóły: [ml-explore/mlx#2133](https://github.com/ml-explore/mlx/issues/2133)

---

## Usuwanie

```bash
./stop.sh
docker rm -f open-webui-mlx tika searxng
docker volume rm open-webui-mlx
rm -rf ~/.cache/huggingface/hub/models--mlx-community--gemma-4-26b-a4b-it-6bit
rm -rf ~/.cache/huggingface/hub/models--mlx-community--whisper-large-v3-mlx
./clean.sh
```
