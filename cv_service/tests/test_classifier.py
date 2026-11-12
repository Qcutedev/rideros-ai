from __future__ import annotations

import io
import json
import shutil

import pytest
from PIL import Image

from app import classifier as classifier_module
from app.classifier import Classifier, InvalidImageError, ModelLoadError
from tests.conftest import CLASSES, jpeg_bytes, write_model


def test_classify_returns_a_class_and_probabilities(model_dir):
    pred = Classifier(model_dir).classify(jpeg_bytes())
    assert pred.label in CLASSES
    assert set(pred.probabilities) == set(CLASSES)
    assert sum(pred.probabilities.values()) == pytest.approx(1.0, abs=1e-3)
    assert pred.confidence == max(pred.probabilities.values())


def test_png_with_alpha_and_odd_sizes_are_accepted(model_dir):
    buf = io.BytesIO()
    Image.new("RGBA", (50, 900), (10, 20, 30, 0)).save(buf, "PNG")
    assert Classifier(model_dir).classify(buf.getvalue()).label in CLASSES


def test_same_photo_same_answer(model_dir):
    clf = Classifier(model_dir)
    assert clf.classify(jpeg_bytes()) == clf.classify(jpeg_bytes())


def test_rejects_bytes_that_are_not_an_image(model_dir):
    with pytest.raises(InvalidImageError):
        Classifier(model_dir).classify(b"%PDF-1.7 not an image")


def test_rejects_images_with_too_many_pixels(model_dir, monkeypatch):
    monkeypatch.setattr(classifier_module, "MAX_PIXELS", 100)
    with pytest.raises(InvalidImageError):
        Classifier(model_dir).classify(jpeg_bytes((20, 20)))


def test_refuses_weights_that_do_not_match_the_hash(model_dir, tmp_path):
    bad = tmp_path / "m"
    shutil.copytree(model_dir, bad)
    meta = json.loads((bad / "metadata.json").read_text())
    meta["weights_sha256"] = "0" * 64
    (bad / "metadata.json").write_text(json.dumps(meta))
    with pytest.raises(ModelLoadError, match="weights_sha256"):
        Classifier(bad)


@pytest.mark.parametrize(
    ("override", "message"),
    [
        ({"arch": "resnet50"}, "architecture"),
        ({"libraries": {"torch": "1.0.0", "torchvision": "0.29.2"}}, "torch"),
    ],
)
def test_refuses_other_architectures_and_torch_releases(tmp_path, override, message):
    with pytest.raises(ModelLoadError, match=message):
        Classifier(write_model(tmp_path / "m", **override))


def test_cpu_and_cuda_builds_of_one_release_are_compatible():
    assert classifier_module._release("2.15.0+cu132") == classifier_module._release("2.15.0+cpu")


def test_missing_files_fail_closed(tmp_path):
    with pytest.raises(ModelLoadError):
        Classifier(tmp_path)
