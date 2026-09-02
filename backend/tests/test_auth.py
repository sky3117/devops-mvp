"""
Integration tests for auth flow. Requires a test DB (see .github/workflows/ci.yml
which spins up a real Postgres service container for these).
"""
import uuid
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_register_and_login():
    email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    password = "SuperSecret123!"

    r = client.post("/api/v1/auth/register", json={"email": email, "password": password, "full_name": "Test User"})
    assert r.status_code == 201
    assert r.json()["email"] == email
    assert r.json()["role"] == "member"

    r = client.post("/api/v1/auth/login", data={"username": email, "password": password})
    assert r.status_code == 200
    assert "access_token" in r.json()


def test_login_wrong_password_fails():
    email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    client.post("/api/v1/auth/register", json={"email": email, "password": "correct-pass"})
    r = client.post("/api/v1/auth/login", data={"username": email, "password": "wrong-pass"})
    assert r.status_code == 401
