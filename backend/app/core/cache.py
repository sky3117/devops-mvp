import json
import redis
from app.core.config import get_settings

settings = get_settings()
redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


def cache_get(key: str):
    val = redis_client.get(key)
    return json.loads(val) if val else None


def cache_set(key: str, value, ttl: int = None):
    redis_client.setex(key, ttl or settings.CACHE_TTL_SECONDS, json.dumps(value))


def cache_delete(key: str):
    redis_client.delete(key)


def cache_delete_pattern(pattern: str):
    for key in redis_client.scan_iter(pattern):
        redis_client.delete(key)
