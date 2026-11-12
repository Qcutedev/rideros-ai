from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path

import pytest
import torch
import torchvision
from PIL import Image

from app.model import ARCH, build_model

CLASSES = ["flooding", "road_damage", "other"]


def write_model(folder: Path, **overrides) -> Path:
    """A randomly initialised (untrained) model folder in the exported layout."""
    folder.mkdir(parents=True, exist_ok=True)
    torch.manual_seed(0)
    torch.save(build_model(len(CLASSES), pretrained=False).state_dict(), folder / "model.pt")
    meta = {
        "name": "road_cv",
        "version": "0.0.0-test",
        "arch": ARCH,
        "classes": CLASSES,
        "weights_sha256": hashlib.sha256((folder / "model.pt").read_bytes()).hexdigest(),
        "libraries": {"torch": torch.__version__, "torchvision": torchvision.__version__},
    }
    meta.update(overrides)
    (folder / "metadata.json").write_text(json.dumps(meta), encoding="utf-8")
    return folder


@pytest.fixture(scope="session")
def model_dir(tmp_path_factory) -> Path:
    return write_model(tmp_path_factory.mktemp("model"))


def jpeg_bytes(size=(320, 240), color=(90, 120, 160)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", size, color).save(buf, "JPEG")
    return buf.getvalue()
