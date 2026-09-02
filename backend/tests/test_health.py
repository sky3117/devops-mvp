from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_liveness():
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json()["status"] == "alive"


def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    assert "service" in resp.json()
