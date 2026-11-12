from __future__ import annotations

from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app
from tests.conftest import CLASSES, jpeg_bytes


def client(**settings) -> TestClient:
    return TestClient(create_app(Settings(**settings)))


def test_classify_answers_label_confidence_and_model(model_dir):
    with client(cv_model_dir=model_dir) as c:
        r = c.post("/classify", files={"image": ("x.jpg", jpeg_bytes(), "image/jpeg")})
    assert r.status_code == 200
    body = r.json()
    assert body["label"] in CLASSES
    assert 0 <= body["confidence"] <= 1
    assert set(body["probabilities"]) == set(CLASSES)
    assert body["model"] == {"name": "road_cv", "version": "0.0.0-test"}


def test_health_names_the_loaded_model(model_dir):
    with client(cv_model_dir=model_dir) as c:
        assert c.get("/health").json() == {
            "status": "ok",
            "model": {"name": "road_cv", "version": "0.0.0-test"},
        }


def test_model_describes_the_loaded_model(model_dir):
    with client(cv_model_dir=model_dir) as c:
        body = c.get("/model").json()
    assert body["name"] == "road_cv"
    assert body["classes"] == CLASSES
    assert body["metrics"] is None  # no metrics.json until `training evaluate` ran


def test_model_serves_metrics_json_verbatim(tmp_path):
    from tests.conftest import write_model

    folder = write_model(tmp_path / "m")
    (folder / "metrics.json").write_text('{"accuracy": 0.5}')
    with client(cv_model_dir=folder) as c:
        assert c.get("/model").json()["metrics"] == {"accuracy": 0.5}


def test_without_a_model_classify_is_503():
    with client(cv_model_dir="") as c:
        assert c.get("/health").json()["status"] == "no_model"
        r = c.post("/classify", files={"image": ("x.jpg", jpeg_bytes(), "image/jpeg")})
        assert c.get("/model").status_code == 503
    assert r.status_code == 503


def test_a_broken_model_folder_starts_without_a_model(tmp_path):
    with client(cv_model_dir=tmp_path) as c:
        assert c.get("/health").json()["status"] == "no_model"


def test_not_an_image_is_415(model_dir):
    with client(cv_model_dir=model_dir) as c:
        r = c.post("/classify", files={"image": ("x.jpg", b"hello", "image/jpeg")})
    assert r.status_code == 415


def test_too_large_is_413(model_dir):
    with client(cv_model_dir=model_dir, cv_max_bytes=1024) as c:
        r = c.post("/classify", files={"image": ("x.jpg", b"\xff" * 2048, "image/jpeg")})
    assert r.status_code == 413


def test_missing_file_field_is_422(model_dir):
    with client(cv_model_dir=model_dir) as c:
        assert c.post("/classify").status_code == 422


def test_no_interactive_docs():
    with client(cv_model_dir="") as c:
        assert c.get("/docs").status_code == 404
