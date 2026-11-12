"""Fine-tune MobileNetV3-Large (ImageNet weights) on data/interim and export the best epoch.

Two stages: the new 3-class head alone for a few epochs, then the whole network with a lower,
cosine-decayed learning rate. The epoch kept is the one with the best validation macro-F1; the test
split is not read here (evaluate.py does that once, after training).
"""

from __future__ import annotations

import hashlib
import json
import random
import subprocess
import time
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path

import numpy as np
import torch
import torchvision
from PIL import Image
from torch import nn
from torch.utils.data import DataLoader, Dataset

from app.model import ARCH, INPUT_SIZE, MEAN, RESIZE, STD, build_model, eval_transform, train_transform
from training.build import CLASSES, read_manifest
from training.paths import INTERIM, MODEL_NAME, ROOT, artifact_dir


@dataclass(frozen=True)
class TrainConfig:
    version: str = "1.0.0"
    seed: int = 42
    batch_size: int = 64
    head_epochs: int = 3
    head_lr: float = 1e-3
    finetune_epochs: int = 15
    finetune_lr: float = 3e-4
    weight_decay: float = 1e-4
    label_smoothing: float = 0.1
    patience: int = 4
    workers: int = 4


class ImageSet(Dataset):
    def __init__(self, rows: list[dict[str, str]], transform) -> None:
        self.rows = rows
        self.transform = transform
        self.index = {c: i for i, c in enumerate(CLASSES)}

    def __len__(self) -> int:
        return len(self.rows)

    def __getitem__(self, i: int):
        row = self.rows[i]
        with Image.open(INTERIM / "images" / f"{row['id']}.jpg") as im:
            image = im.convert("RGB")
        return self.transform(image), self.index[row["label"]]


def seed_everything(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)


def macro_f1(y_true: list[int], y_pred: list[int], n: int) -> float:
    scores = []
    for c in range(n):
        tp = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == c and p == c)
        fp = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t != c and p == c)
        fn = sum(1 for t, p in zip(y_true, y_pred, strict=True) if t == c and p != c)
        prec = tp / (tp + fp) if tp + fp else 0.0
        rec = tp / (tp + fn) if tp + fn else 0.0
        scores.append(2 * prec * rec / (prec + rec) if prec + rec else 0.0)
    return sum(scores) / n


@torch.inference_mode()
def predict(model: nn.Module, loader: DataLoader, device: torch.device) -> tuple[list[int], np.ndarray]:
    model.eval()
    labels: list[int] = []
    probs: list[np.ndarray] = []
    for x, y in loader:
        with torch.autocast(device.type, enabled=device.type == "cuda"):
            logits = model(x.to(device, non_blocking=True))
        probs.append(torch.softmax(logits.float(), dim=1).cpu().numpy())
        labels += y.tolist()
    return labels, np.concatenate(probs)


def _run_epoch(model, loader, device, optimizer, scheduler, loss_fn, scaler) -> float:
    model.train()
    total, count = 0.0, 0
    for x, y in loader:
        x, y = x.to(device, non_blocking=True), y.to(device, non_blocking=True)
        optimizer.zero_grad(set_to_none=True)
        with torch.autocast(device.type, enabled=device.type == "cuda"):
            loss = loss_fn(model(x), y)
        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()
        if scheduler is not None:
            scheduler.step()
        total += loss.item() * len(y)
        count += len(y)
    return total / count


def git_commit() -> str:
    try:
        sha = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()
        dirty = subprocess.run(
            ["git", "status", "--porcelain", "--", "."], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()
    except OSError, subprocess.CalledProcessError:
        return "unknown"
    return f"{sha}{'-dirty' if dirty else ''}"


def train(cfg: TrainConfig | None = None, *, log=print) -> Path:
    cfg = cfg or TrainConfig()
    seed_everything(cfg.seed)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    rows = read_manifest()
    by_split = {s: [r for r in rows if r["split"] == s] for s in ("train", "val")}
    loaders = {
        "train": DataLoader(
            ImageSet(by_split["train"], train_transform()),
            batch_size=cfg.batch_size,
            shuffle=True,
            num_workers=cfg.workers,
            pin_memory=True,
            persistent_workers=cfg.workers > 0,
            generator=torch.Generator().manual_seed(cfg.seed),
            drop_last=True,
        ),
        "val": DataLoader(
            ImageSet(by_split["val"], eval_transform()),
            batch_size=cfg.batch_size * 2,
            num_workers=cfg.workers,
            pin_memory=True,
            persistent_workers=cfg.workers > 0,
        ),
    }
    model = build_model(len(CLASSES), pretrained=True).to(device)
    loss_fn = nn.CrossEntropyLoss(label_smoothing=cfg.label_smoothing)
    scaler = torch.amp.GradScaler(enabled=device.type == "cuda")
    history: list[dict] = []
    best: dict = {"f1": -1.0}
    started = time.perf_counter()

    def evaluate_epoch(stage: str, epoch: int, train_loss: float) -> bool:
        y, p = predict(model, loaders["val"], device)
        pred = p.argmax(1).tolist()
        f1 = macro_f1(y, pred, len(CLASSES))
        acc = sum(int(a == b) for a, b in zip(y, pred, strict=True)) / len(y)
        history.append(
            {
                "stage": stage,
                "epoch": epoch,
                "train_loss": round(train_loss, 4),
                "val_macro_f1": round(f1, 4),
                "val_accuracy": round(acc, 4),
            }
        )
        log(f"[{stage} {epoch}] loss {train_loss:.4f} val macro-F1 {f1:.4f} acc {acc:.4f}")
        if f1 > best["f1"]:
            best.update(
                f1=f1,
                stage=stage,
                epoch=epoch,
                state={k: v.detach().cpu().clone() for k, v in model.state_dict().items()},
            )
            return True
        return False

    # Stage 1: head only.
    for param in model.features.parameters():
        param.requires_grad = False
    head_params = [p for p in model.parameters() if p.requires_grad]
    optimizer = torch.optim.AdamW(head_params, lr=cfg.head_lr, weight_decay=cfg.weight_decay)
    for epoch in range(1, cfg.head_epochs + 1):
        loss = _run_epoch(model, loaders["train"], device, optimizer, None, loss_fn, scaler)
        evaluate_epoch("head", epoch, loss)

    # Stage 2: everything, cosine decay per step, early stop on validation macro-F1.
    for param in model.parameters():
        param.requires_grad = True
    optimizer = torch.optim.AdamW(model.parameters(), lr=cfg.finetune_lr, weight_decay=cfg.weight_decay)
    steps = cfg.finetune_epochs * len(loaders["train"])
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=steps)
    stale = 0
    for epoch in range(1, cfg.finetune_epochs + 1):
        loss = _run_epoch(model, loaders["train"], device, optimizer, scheduler, loss_fn, scaler)
        stale = 0 if evaluate_epoch("finetune", epoch, loss) else stale + 1
        if stale >= cfg.patience:
            log(f"early stop: no validation gain for {cfg.patience} epochs")
            break

    out = artifact_dir(cfg.version)
    out.mkdir(parents=True, exist_ok=True)
    weights = out / "model.pt"
    torch.save(best["state"], weights)
    digest = hashlib.sha256(weights.read_bytes()).hexdigest()
    build_summary = json.loads((INTERIM / "build_summary.json").read_text(encoding="utf-8"))
    metadata = {
        "name": MODEL_NAME,
        "version": cfg.version,
        "arch": ARCH,
        "pretrained_weights": "torchvision MobileNet_V3_Large_Weights.IMAGENET1K_V2",
        "classes": list(CLASSES),
        "input": {"resize": RESIZE, "crop": INPUT_SIZE, "mean": MEAN, "std": STD},
        "weights_sha256": digest,
        "libraries": {"torch": torch.__version__, "torchvision": torchvision.__version__},
        "trained_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "train_seconds": round(time.perf_counter() - started, 1),
        "device": torch.cuda.get_device_name(0) if device.type == "cuda" else "cpu",
        "git_commit": git_commit(),
        "config": asdict(cfg),
        "selected": {"stage": best["stage"], "epoch": best["epoch"], "val_macro_f1": round(best["f1"], 4)},
        "history": history,
        "data": build_summary["kept"],
    }
    (out / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    log(f"saved {weights} (best {best['stage']} epoch {best['epoch']}, val macro-F1 {best['f1']:.4f})")
    return out
