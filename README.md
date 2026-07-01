# Astro: Portable Local AI on a USB Drive

A cross-platform, offline-first LLM setup that runs entirely from a USB drive —
no install, no internet connection, no cloud dependency. Plug it into a
Windows, macOS, or Linux machine and get a local ChatGPT-style interface
running against an open-weight model, in seconds.

Built as a learning project to understand local LLM inference, portable
runtime packaging, and cross-platform tooling.

## Why

Running an LLM locally means the prompts never leave the machine — useful
for air-gapped environments, locked-down corporate laptops, or just wanting
a private assistant with zero subscription cost. Most local-LLM setups
(Ollama, LM Studio) require installing something on the host machine first.
This project avoids that entirely by keeping the runtime and models on the
drive itself.

## How it works

- **Runtime: [llamafile](https://github.com/Mozilla-Ocho/llamafile)** — a
  single, self-contained executable (built on the Cosmopolitan libc project)
  that runs natively on Windows, macOS, and Linux without installation. It
  bundles an inference engine (llama.cpp) and a local web server with a
  built-in chat UI.
- **Models: standard instruct-tuned open-weight models** in GGUF format,
  quantized to Q4_K_M (a good balance of file size vs. output quality for
  CPU inference). No fine-tuning or modification — these are the vendors'
  own safety-aligned releases.
- **Filesystem: exFAT** — the only format natively readable/writable across
  Windows, macOS, and Linux, and the only one without FAT32's 4 GB
  file-size ceiling (model files are several GB each).

## Repo layout

```
ASTRO/
├── bin/                    # llamafile runtime (not committed - see setup)
├── models/                 # GGUF model files (not committed - see setup)
├── run.sh                  # Launcher for Linux / macOS
├── run.bat                 # Launcher for Windows
├── download-models.sh      # Pulls model weights from Hugging Face
└── README.md
```

Model weights and the llamafile binary are **not committed to this repo** —
they're multi-GB binaries and don't belong in git history. Use the setup
steps below to fetch them.

## Models used

| Tier | Model | Quant | Approx size | Use case |
|---|---|---|---|---|
| Fast | Llama 3.2 3B Instruct | Q4_K_M | ~2 GB | Quick responses, low-power hardware |
| Daily driver | Qwen2.5 7B Instruct | Q4_K_M | ~4.5 GB | General use, best speed/quality balance |
| Heavy | Qwen2.5 14B Instruct | Q4_K_M | ~9 GB | Stronger reasoning, needs more RAM/CPU |

All are the official instruct releases with standard vendor safety tuning —
no abliterated or uncensored variants are used in this build.

## Setup

1. **Format a USB drive as exFAT** (256 GB+ recommended if carrying all
   three model tiers; 32 GB is enough for the Fast + Daily Driver tiers).
2. **Clone this repo onto the drive.**
3. **Download the llamafile runtime** from the
   [releases page](https://github.com/Mozilla-Ocho/llamafile/releases) and
   place it at `bin/llamafile` (Linux/macOS) — copy the same file to
   `bin/llamafile.exe` for Windows.
4. **Fetch model weights:**
   ```bash
   chmod +x download-models.sh
   ./download-models.sh
   ```
   Choose which tier(s) to download when prompted. On Windows, run this via
   WSL or Git Bash, or download the `.gguf` files manually from the URLs
   inside the script.
5. **Launch:**
   ```bash
   chmod +x run.sh bin/llamafile
   ./run.sh
   ```
   On Windows, double-click `run.bat` or run it from a command prompt.
6. Open `http://127.0.0.1:8080` in a browser once the model finishes
   loading.

Pass a model path as an argument to skip the interactive picker, e.g.:
```bash
./run.sh models/qwen2.5-7b-instruct.Q4_K_M.gguf
```

## Design notes / tradeoffs

- **Drive speed matters more than capacity.** Model loading is I/O bound —
  a slow USB 2.0 stick can take minutes to load a 5 GB model. This build
  assumes a USB 3.2 drive or portable SSD with genuine sustained read
  speeds (not just burst).
- **Q4_K_M quantization** was chosen as the default: roughly a 4x size
  reduction vs. full precision with modest, usually imperceptible quality
  loss for general chat use. Q5_K_M or Q8_0 are worth trying if quality
  matters more than footprint and the extra size is affordable.
- **CPU-only inference is assumed.** On hardware without a dedicated GPU
  (this was tested on an Intel MacBook Pro, T2 chip, no discrete GPU), the
  3B and 7B tiers are usable in real time; the 14B tier is noticeably
  slower and better suited to hardware with more cores or a GPU.
- **No abliteration / uncensoring.** Earlier iterations of this project
  explored uncensored (abliterated) models for unrestricted experimentation.
  This version deliberately uses only vendor-released, safety-tuned
  instruct models, since the repo is public and intended as a portfolio /
  learning artifact.

## Tested on

- Intel MacBook Pro 2020 (T2 chip), macOS
- *(add other machines as tested)*

## License

MIT — see `LICENSE`. Model weights are subject to their respective
upstream licenses (Meta Llama Community License, Apache 2.0 for Qwen).
