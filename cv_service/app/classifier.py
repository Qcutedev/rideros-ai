"""Load an exported model folder and classify one photo.

A model folder holds `model.pt` (a state_dict, loaded with weights_only=True) and `metadata.json`.
Loading fails closed: wrong file hash, unknown architecture, or a torch/torchvision release other than
the one the model was trained with raises `ModelLoadError`.
"""

from __future__ import annotations

import hashlib
import io
import json
import threading
from dataclasses import dataclass
from pathlib import Path

import torch
import torchvision
from PIL import Image, ImageOps, UnidentifiedImageError

from app.model import ARCH, build_model, eval_transform

MAX_PIXELS = 40_000_000


class ModelLoadError(RuntimeError):
    pass


class InvalidImageError(ValueError):
    pass


@dataclass(frozen=True)
class Prediction:
    label: str
    confidence: float
    probabilities: dict[str, float]


def _release(version: str) -> str:
    """'2.15.0+cpu' -> '2.15.0' (CPU and CUDA builds of one release give the same weights layout)."""
    return version.split("+", 1)[0]


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(1 << 20):
            h.update(chunk)
    return h.hexdigest()


class Classifier:
    def __init__(self, model_dir: Path, *, threads: int = 1) -> None:
        meta_path, weights_path = model_dir / "metadata.json", model_dir / "model.pt"
        if not meta_path.is_file() or not weights_path.is_file():
            raise ModelLoadError(f"{model_dir} needs metadata.json and model.pt")
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        if meta.get("arch") != ARCH:
            raise ModelLoadError(f"unsupported architecture {meta.get('arch')!r}")
        if _sha256(weights_path) != meta.get("weights_sha256"):
            raise ModelLoadError("model.pt does not match weights_sha256 in metadata.json")
        libs = meta.get("libraries", {})
        for name, installed in (("torch", torch.__version__), ("torchvision", torchvision.__version__)):
            if _release(libs.get(name, "")) != _release(installed):
                raise ModelLoadError(f"model needs {name} {libs.get(name)}, installed {installed}")

        self.name: str = meta["name"]
        self.version: str = meta["version"]
        self.classes: list[str] = list(meta["classes"])
        self.metadata: dict = meta
        # Test-split metrics written by `python -m training evaluate` (None before evaluation).
        metrics_path = model_dir / "metrics.json"
        self.metrics: dict | None = (
            json.loads(metrics_path.read_text(encoding="utf-8")) if metrics_path.is_file() else None
        )
        torch.set_num_threads(threads)
        model = build_model(len(self.classes), pretrained=False)
        model.load_state_dict(torch.load(weights_path, map_location="cpu", weights_only=True))
        self._model = model.eval()
        self._transform = eval_transform()
        self._lock = threading.Lock()

    @staticmethod
    def decode(data: bytes) -> Image.Image:
        try:
            image = Image.open(io.BytesIO(data))
            if image.width * image.height > MAX_PIXELS:
                raise InvalidImageError("image has too many pixels")
            image = ImageOps.exif_transpose(image)
            return image.convert("RGB")
        except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
            raise InvalidImageError("not a readable image") from exc

    def predict(self, image: Image.Image) -> Prediction:
        batch = self._transform(image).unsqueeze(0)
        with self._lock, torch.inference_mode():
            probs = torch.softmax(self._model(batch), dim=1)[0].tolist()
        best = max(range(len(probs)), key=probs.__getitem__)
        return Prediction(
            label=self.classes[best],
            confidence=round(probs[best], 4),
            probabilities={c: round(p, 4) for c, p in zip(self.classes, probs, strict=True)},
        )

    def classify(self, data: bytes) -> Prediction:
        return self.predict(self.decode(data))
