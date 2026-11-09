"""The real exported model (ml/artifacts, gitignored) loads in the backend and predicts like the ML package.

Skipped when the artifact is absent (fresh clone / CI without the licence-restricted data).
"""

import json
from datetime import datetime
from pathlib import Path

import httpx
import pytest
from rideros_ml.features.inference import make_feature_row

from app.main import create_app
from app.ml import predictor
from app.ml.registry import load_model
from tests.conftest import make_settings
from tests.helpers import auth_headers

ARTIFACTS = Path(__file__).resolve().parents[3] / "ml" / "artifacts"
NAME, VERSION = "pickup_o2p", "1.0.0"
FOLDER = ARTIFACTS / NAME / VERSION

pytestmark = pytest.mark.skipif(
    not (FOLDER / "pipeline.joblib").is_file(), reason="real artifact not present"
)


@pytest.fixture(scope="module")
def model():
    return load_model(ARTIFACTS, NAME, VERSION)


async def test_backend_prediction_equals_direct_pipeline_call(model) -> None:
    local = datetime(2022, 10, 24, 11, 45)
    direct = float(model.pipeline.predict(make_feature_row("0", "0", local))[0])
    result = await predictor.predict(model, poi_id="0", da_id="0", local_time=local)
    assert result.minutes == pytest.approx(max(direct, 0.0))
    conformal = json.loads((FOLDER / "conformal.json").read_text(encoding="utf-8"))
    assert result.high == pytest.approx(result.minutes + conformal["q_high"])


async def test_model_info_reports_stored_test_metrics(database_url: str) -> None:
    metrics = json.loads((FOLDER / "metrics.json").read_text(encoding="utf-8"))
    app = create_app(
        make_settings(database_url, model_dir=ARTIFACTS, active_model_name=NAME, active_model_version=VERSION)
    )
    async with app.router.lifespan_context(app):
        transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
        async with httpx.AsyncClient(transport=transport, base_url="http://test/api/v1") as client:
            h = await auth_headers(client, "real-model@example.com")
            body = (await client.get("/pickup/model", headers=h)).json()
    selected = metrics["selected_model"]
    assert body["version"] == VERSION and body["test_metrics"]["model"] == selected
    assert body["test_metrics"]["mae"] == metrics["test"][selected]["mae"]
    assert body["interval"]["test_coverage"] == metrics["conformal_test"]["coverage"]
    assert any("not seen in training" in item for item in body["limitations"])
