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

- **Runtime: [llamafile](https://github.com/mozilla-ai/llamafile)** — a
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
   [releases page](https://github.com/mozilla-ai/llamafile/releases) and
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

## Usage

Once set up (runtime in `bin/`, at least one model in `models/`), running it
is the same on every launch:

**macOS / Linux**
```bash
cd /path/to/ASTRO      # e.g. /Volumes/ASTRO/ASTRO on macOS
./run.sh
```

**Windows**
```cmd
cd X:\ASTRO            # whatever drive letter the USB mounts as
run.bat
```

Then:
1. Pick a model from the numbered menu.
2. Wait for it to finish loading (the terminal stops scrolling and sits idle).
3. Open `http://127.0.0.1:8080` in any browser for the chat UI — or just
   type directly in the terminal, which is also an interactive chat.

Keep the terminal window open while using the web UI — closing it (or
`Ctrl+C`) stops the server. To skip the menu and load a specific model
directly, pass its path as an argument:
```bash
./run.sh models/qwen2.5-7b-instruct.Q4_K_M.gguf
```

Every session is fresh and stateless — the model retains nothing between
launches.

## Keeping the runtime up to date

The pinned llamafile version lives in [`.llamafile-version`](./.llamafile-version),
and a scheduled GitHub Actions workflow opens an issue whenever upstream ships
a newer release. See [UPDATING.md](./UPDATING.md) for the full update process.

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

## Troubleshooting

**`./download-models.sh` fails with `line 15: llama: unbound variable`**
This happens on macOS, which ships bash 3.2 (2007) by default rather than
bash 4+, for licensing reasons. Bash 3.2 doesn't support associative arrays
(`declare -A`), which the script originally used. Fixed in this repo by
rewriting the model list as plain named variables instead of an associative
array — no action needed if you're using the current version of the script,
but worth knowing if you ever see this class of error with other scripts on
macOS.

**`run.sh` fails or behaves oddly with array-related errors**
Same root cause as above — `mapfile`/`readarray` are bash 4+ only. Fixed by
building the model list with a `while read` loop instead.

**Drive shows a nested folder, e.g. `/Volumes/ASTRO/ASTRO/...`**
If you drag the whole `ASTRO` project folder onto a drive you've also
labeled `ASTRO`, you end up with drive-name/folder-name nesting. Not a bug —
just `cd` into the inner folder. Run `ls -la` at the drive root if you're
ever unsure of the actual path before running scripts.

**macOS blocks the binary with "cannot be opened, unidentified developer"**
Clear the quarantine flag once after copying the binary onto the drive:
```bash
xattr -d com.apple.quarantine bin/llamafile
```
`run.sh` also does this automatically on every launch, so it's normally a
non-issue — only relevant if you're running the binary manually outside the
launcher.

**Web UI shows `ERR_CONNECTION_REFUSED` at `127.0.0.1:8080`**
The server isn't running. `run.sh`/`run.bat` need to stay open in their
terminal window the whole time you're using the web UI — closing that
terminal (or `Ctrl+C`) kills the server. Relaunch and leave the terminal
open in the background.

**No memory between sessions**
By design. Each launch is a fresh, stateless instance — the model doesn't
retain names, facts, or prior conversation across restarts. Persistent
memory would require an additional RAG/vector-store layer, which is out of
scope for this build.

## Tested on

- Intel MacBook Pro 2020 (T2 chip, i9-9880H), macOS — Llama 3.2 3B Q4_K_M
  confirmed working via both CLI chat and web UI, ~10.7 tokens/sec
- *(add other machines as tested)*

## License

MIT — see `LICENSE`. Model weights are subject to their respective
upstream licenses (Meta Llama Community License, Apache 2.0 for Qwen).
