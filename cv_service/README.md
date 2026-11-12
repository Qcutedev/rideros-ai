# RiderOS AI — road photo classifier (`cv_service/`)

Phase 5 (P5c). This folder holds a small FastAPI service with one job, `POST /classify`. It suggests a
category for a rider's report photo: `flooding`, `road_damage` or `other`. The backend calls it in a
background task after the report is saved and stores the result as a **suggestion only**
(`incident_reports.ai_label` / `ai_confidence`). The suggestion never changes the report's category or
the incident's status. The app shows "AI แนะนำ: … (xx%)" with an `ค่าประมาณ` badge, and below 0.6 it shows
"AI ไม่แน่ใจ" instead.

- `app/`: the service, plus the network and preprocessing it shares with training (`app/model.py`)
- `training/`: the offline pipeline (`download → build → train → evaluate`)
- `data/`: gitignored, except `data/SOURCES.md` (license review and provenance)
- `artifacts/road_cv/<version>/`: gitignored (`model.pt`, `metadata.json`, `metrics.json`)
- `reports/<version>/`: committed (`metrics.json`, `confusion_matrix.png`, `model_card.md`)

Model: torchvision MobileNetV3-Large, fine-tuned from the ImageNet-1k V2 weights. Data: RDD2022 +
AlleyFloodNet + Flood10k. **No photos from Thailand.** The model is non-commercial; see
`data/SOURCES.md` for why.

## Setup

uv is a separate project here, so torch never enters `ml/` or the backend. On Windows, torch comes from
the PyTorch CUDA 13.2 index, used for training. In the Linux docker image it comes from the CPU index.

```powershell
cd "C:\dev\RiderOS AI\cv_service"
python -m uv sync                 # .venv with torch (CUDA on Windows), dev + train groups
python -m uv run pytest           # service + pipeline tests (no dataset or GPU needed)
python -m uv run ruff check . ; python -m uv run ruff format --check .
```

## Training pipeline

```powershell
# 1. RDD2022 (4 country zips by HTTP range, ~1.4 GB) + Flood10k (747 MB); AlleyFloodNet zip from Kaggle by hand
python -m uv run python -m training download --alley "$HOME\Downloads\archive.zip"
# 2. Labels, near-duplicate removal, group split, images shrunk to 256 px -> data/interim/
python -m uv run python -m training build
# 3. Fine-tune on the GPU -> artifacts/road_cv/1.0.0/{model.pt, metadata.json}
python -m uv run python -m training train
# 4. Test split, through the serving code -> reports/1.0.0/metrics.json + confusion_matrix.png
python -m uv run python -m training evaluate
```

- Every raw file is pinned by SHA-256 in `training/sources.py`. A missing or changed pin stops `download`.
- Splits: AlleyFloodNet keeps its published split. For RDD2022, blocks of 25 consecutive frame numbers
  go to one split together, because neighbouring frames look alike. Flood10k is split per image after
  near-duplicates (dHash within 3 bits) are removed.
- The epoch kept is the one with the best validation macro-F1. The test split is read once, in `evaluate`.

## Service

| Endpoint | Answer |
|---|---|
| `GET /health` | `{"status": "ok" \| "no_model", "model": {name, version} \| null}` |
| `GET /model` | name, version, classes, inputs, training data counts and `metrics.json` verbatim (503 without a model) |
| `POST /classify` (multipart `image`) | `{"label", "confidence", "probabilities", "model": {name, version}}` · 413 `image_too_large` (> 5 MB) · 415 `unsupported_image` · 503 `model_unavailable` |

Settings: `CV_MODEL_DIR` (a folder with `model.pt` + `metadata.json`; unset means 503),
`CV_MAX_BYTES` (5 MB), and `CV_THREADS` (1). Loading fails closed if the `model.pt` hash differs from
`metadata.json`, if the architecture is unknown, or if the torch/torchvision release differs from the
one used for training.

`docker compose up` starts it as the `cv` service. It has no published port: only the backend calls it,
over the compose network (`CV_SERVICE_URL=http://cv:8100`). `cv_service/artifacts` is mounted read-only
at `/models`.
