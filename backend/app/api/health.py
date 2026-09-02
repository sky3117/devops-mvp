from fastapi import APIRouter, Response, status
from sqlalchemy import text
from app.core.database import SessionLocal
from app.core.cache import redis_client

router = APIRouter(tags=["health"])


@router.get("/healthz")
def liveness():
    """Liveness probe - is the process alive? Keep this cheap, no external calls."""
    return {"status": "alive"}


@router.get("/readyz")
def readiness(response: Response):
    """Readiness probe - can this pod actually serve traffic? Checks DB + Redis."""
    checks = {"database": False, "redis": False}

    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        checks["database"] = True
    except Exception:
        pass

    try:
        redis_client.ping()
        checks["redis"] = True
    except Exception:
        pass

    if not all(checks.values()):
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    return {"status": "ready" if all(checks.values()) else "not_ready", "checks": checks}
