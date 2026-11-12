"""Score the exported model once on the held-out test split, through the serving code path.

The model is loaded with `app.classifier.Classifier` (the class the service uses: hash check, CPU,
eval preprocessing), so the numbers describe what /classify returns. Writes
reports/<version>/metrics.json and confusion_matrix.png (the model card next to them is written by hand),
and copies metrics.json into the model folder for the service.
"""

from __future__ import annotations

import json
import statistics
import time
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

from app.classifier import Classifier
from training.build import CLASSES, read_manifest
from training.paths import INTERIM, artifact_dir, report_dir

# The app shows "AI ไม่แน่ใจ" below this confidence (decision 10, HANDOFF §4.11).
UI_THRESHOLD = 0.6


def per_class(y_true: list[str], y_pred: list[str]) -> dict[str, dict[str, float]]:
    out = {}
    for c in CLASSES:
        tp = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == c and p == c)
        fp = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t != c and p == c)
        fn = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == c and p != c)
        prec = tp / (tp + fp) if tp + fp else 0.0
        rec = tp / (tp + fn) if tp + fn else 0.0
        f1 = 2 * prec * rec / (prec + rec) if prec + rec else 0.0
        out[c] = {
            "precision": round(prec, 4),
            "recall": round(rec, 4),
            "f1": round(f1, 4),
            "support": sum(1 for t in y_true if t == c),
        }
    return out


def confusion(y_true: list[str], y_pred: list[str]) -> list[list[int]]:
    counts = Counter(zip(y_true, y_pred, strict=True))
    return [[counts[(t, p)] for p in CLASSES] for t in CLASSES]


def accuracy(y_true: list[str], y_pred: list[str]) -> float:
    return sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == p) / len(y_true) if y_true else 0.0


def latency_ms(clf: Classifier, folder: Path, *, warmup: int = 5) -> dict:
    """End-to-end classify (decode + preprocess + forward) on full-size test photos, one thread."""
    files = sorted(folder.glob("*.jpg"))
    if not files:
        return {}
    payloads = [f.read_bytes() for f in files]
    for data in payloads[:warmup]:
        clf.classify(data)
    times = []
    for data in payloads:
        start = time.perf_counter()
        clf.classify(data)
        times.append((time.perf_counter() - start) * 1000)
    times.sort()
    return {
        "images": len(times),
        "median_ms": round(statistics.median(times), 1),
        "p95_ms": round(times[min(len(times) - 1, int(0.95 * len(times)))], 1),
    }


def plot_confusion(matrix: list[list[int]], path: Path) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(5, 4.2))
    ax.imshow(matrix, cmap="Greens")
    ax.set_xticks(range(len(CLASSES)), CLASSES, rotation=20)
    ax.set_yticks(range(len(CLASSES)), CLASSES)
    ax.set_xlabel("predicted")
    ax.set_ylabel("true")
    peak = max(max(r) for r in matrix) or 1
    for i, row in enumerate(matrix):
        for j, v in enumerate(row):
            ax.text(j, i, str(v), ha="center", va="center", color="white" if v > peak / 2 else "black")
    ax.set_title("Test split confusion matrix")
    fig.tight_layout()
    fig.savefig(path, dpi=150)
    plt.close(fig)


def evaluate(version: str = "1.0.0", *, threads: int = 4, log=print) -> dict:
    model_dir = artifact_dir(version)
    clf = Classifier(model_dir, threads=threads)
    meta = json.loads((model_dir / "metadata.json").read_text(encoding="utf-8"))
    rows = [r for r in read_manifest() if r["split"] == "test"]
    y_true, y_pred, conf = [], [], []
    for row in rows:
        with Image.open(INTERIM / "images" / f"{row['id']}.jpg") as im:
            pred = clf.predict(im.convert("RGB"))
        y_true.append(row["label"])
        y_pred.append(pred.label)
        conf.append(pred.confidence)

    majority = Counter(r["label"] for r in read_manifest() if r["split"] == "train").most_common(1)[0][0]
    by_source: dict[str, dict[str, list[str]]] = defaultdict(lambda: {"t": [], "p": []})
    for row, p in zip(rows, y_pred, strict=True):
        key = f"{row['source']}|{row['label']}"
        by_source[key]["t"].append(row["label"])
        by_source[key]["p"].append(p)
    confident = [(t, p) for t, p, c in zip(y_true, y_pred, conf, strict=True) if c >= UI_THRESHOLD]
    pc = per_class(y_true, y_pred)
    matrix = confusion(y_true, y_pred)
    torch_threads_latency = latency_ms(Classifier(model_dir, threads=1), INTERIM / "bench")
    metrics = {
        "model": {"name": meta["name"], "version": meta["version"], "git_commit": meta["git_commit"]},
        "test_images": len(rows),
        "accuracy": round(accuracy(y_true, y_pred), 4),
        "macro_f1": round(sum(v["f1"] for v in pc.values()) / len(pc), 4),
        "baseline_majority_class": {
            "class": majority,
            "accuracy": round(sum(1 for t in y_true if t == majority) / len(y_true), 4),
        },
        "per_class": pc,
        "confusion_matrix": {"labels": list(CLASSES), "rows_true_cols_pred": matrix},
        "by_source_accuracy": {
            k: {"accuracy": round(accuracy(v["t"], v["p"]), 4), "n": len(v["t"])}
            for k, v in sorted(by_source.items())
        },
        "ui_threshold": {
            "threshold": UI_THRESHOLD,
            "coverage": round(len(confident) / len(rows), 4),
            "accuracy_when_shown": round(accuracy([t for t, _ in confident], [p for _, p in confident]), 4),
        },
        "latency_host_cpu_1_thread": torch_threads_latency,
    }
    out = report_dir(version)
    out.mkdir(parents=True, exist_ok=True)
    text = json.dumps(metrics, indent=2)
    (out / "metrics.json").write_text(text, encoding="utf-8")
    # The service serves this copy at GET /model; the backend stores it in model_versions.metrics.
    (model_dir / "metrics.json").write_text(text, encoding="utf-8")
    plot_confusion(matrix, out / "confusion_matrix.png")
    log(json.dumps({k: metrics[k] for k in ("accuracy", "macro_f1", "ui_threshold")}, indent=2))
    return metrics
