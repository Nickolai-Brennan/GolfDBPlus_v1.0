"""Low-level API helpers for making requests to the PGA Tour API.

Adapted from WalrusQuant/pgatourPY under the MIT license preserved in
``LICENSES/pgatourPY-MIT.txt``.
"""

from __future__ import annotations

import base64
import binascii
import gzip
import hashlib
import json
import logging
import os
import random
import time
from pathlib import Path
from typing import Any

import httpx

GRAPHQL_URL = "https://orchestrator.pgatour.com/graphql"
REST_URL = "https://data-api.pgatour.com"
CONFIG_URL = "https://orchestrator-config.pgatour.com"
_DEFAULT_API_KEY = "da2-gsrx5bibzbb4njvhl7t37wqyl4"

USER_AGENT = "pgatourPY (https://github.com/WalrusQuant/pgatourPY)"

_RETRY_STATUS = {408, 429, 500, 502, 503, 504}
_MAX_RETRIES = 3
_TIMEOUT_SECONDS = 30.0
_BACKOFF_BASE = 0.5

_QUERY_DIR = Path(__file__).parent / "graphql"
_QUERY_CACHE: dict[str, str] = {}

_MIN_INTERVAL = 0.1  # 10 req/s ceiling
_last_request_time: float = 0.0

logger = logging.getLogger("pga_tour_api")
_CACHE_MISS = object()


class PgaTourError(RuntimeError):
    """Raised when a PGA Tour API call fails in a way the caller may want to handle."""


def _api_key() -> str:
    """Return the API key, preferring the PGA_API_KEY env var if set."""
    return os.environ.get("PGA_API_KEY") or _DEFAULT_API_KEY


def _is_verbose() -> bool:
    """PGATOUR_VERBOSE truthy => log request envelopes at INFO level."""
    raw = os.environ.get("PGATOUR_VERBOSE", "").strip().lower()
    return raw not in ("", "0", "false", "no", "off")


def _headers() -> dict[str, str]:
    return {
        "Content-Type": "application/json",
        "Accept": "application/graphql-response+json, application/json",
        "x-api-key": _api_key(),
        "x-pgat-platform": "web",
        "Origin": "https://www.pgatour.com",
        "Referer": "https://www.pgatour.com/",
        "User-Agent": USER_AGENT,
    }


def _read_query(operation_name: str) -> str:
    """Read a GraphQL query from the graphql/ directory, with caching."""
    if operation_name in _QUERY_CACHE:
        return _QUERY_CACHE[operation_name]
    path = _QUERY_DIR / f"{operation_name}.graphql"
    if not path.exists():
        raise FileNotFoundError(f"GraphQL query not found: {path}")
    query = path.read_text()
    _QUERY_CACHE[operation_name] = query
    return query


def _throttle() -> None:
    global _last_request_time
    now = time.monotonic()
    elapsed = now - _last_request_time
    if elapsed < _MIN_INTERVAL:
        time.sleep(_MIN_INTERVAL - elapsed)
    _last_request_time = time.monotonic()


def _cache_path(namespace: str, key: Any) -> Path | None:
    """Return an opt-in cache path for a request, or ``None`` when disabled."""
    root = os.environ.get("PGATOUR_CACHE_DIR")
    if not root:
        return None
    digest = hashlib.sha256(
        json.dumps(key, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return Path(root).expanduser() / namespace / f"{digest}.json"


def _cache_ttl() -> float:
    raw = os.environ.get("PGATOUR_CACHE_TTL", "86400")
    try:
        return max(0.0, float(raw))
    except ValueError:
        logger.warning("invalid PGATOUR_CACHE_TTL=%r; using 86400 seconds", raw)
        return 86400.0


def _cache_read(namespace: str, key: Any) -> Any:
    path = _cache_path(namespace, key)
    if path is None or _cache_ttl() == 0:
        return _CACHE_MISS
    try:
        if time.time() - path.stat().st_mtime > _cache_ttl():
            return _CACHE_MISS
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, json.JSONDecodeError):
        return _CACHE_MISS


def _cache_write(namespace: str, key: Any, value: Any) -> None:
    path = _cache_path(namespace, key)
    if path is None or _cache_ttl() == 0:
        return
    try:
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        temporary = path.with_suffix(".tmp")
        temporary.write_text(json.dumps(value), encoding="utf-8")
        temporary.replace(path)
    except (OSError, TypeError, ValueError):
        # Caching must never make a successful API call fail.
        logger.debug("could not write cache entry %s", path, exc_info=True)


def _request_with_retry(
    method: str,
    url: str,
    *,
    json_body: dict[str, Any] | None = None,
    context: str,
) -> httpx.Response:
    """Issue an HTTP request with bounded retries on transient failures."""
    last_exc: Exception | None = None
    for attempt in range(_MAX_RETRIES):
        _throttle()
        try:
            resp = httpx.request(
                method,
                url,
                json=json_body,
                headers=_headers(),
                timeout=_TIMEOUT_SECONDS,
            )
        except (httpx.TimeoutException, httpx.TransportError) as e:
            last_exc = e
            logger.debug(
                "pga_tour_api %s transport error on %s (attempt %d/%d): %s",
                context, url, attempt + 1, _MAX_RETRIES, e,
            )
            if attempt + 1 >= _MAX_RETRIES:
                raise PgaTourError(
                    f"transport error calling {context}: {e}"
                ) from e
            time.sleep(_BACKOFF_BASE * (2 ** attempt) + random.uniform(0, 0.1))
            continue

        if resp.status_code in _RETRY_STATUS and attempt + 1 < _MAX_RETRIES:
            logger.debug(
                "pga_tour_api %s got %d (attempt %d/%d), retrying",
                context, resp.status_code, attempt + 1, _MAX_RETRIES,
            )
            time.sleep(_BACKOFF_BASE * (2 ** attempt) + random.uniform(0, 0.1))
            continue

        return resp

    # Should be unreachable, but defend it.
    raise PgaTourError(
        f"exhausted retries calling {context}: {last_exc}"
    )


def _parse_json(resp: httpx.Response, context: str) -> Any:
    """Parse a JSON response body; raise a clear error if it isn't JSON."""
    try:
        return resp.json()
    except (ValueError, json.JSONDecodeError) as e:
        snippet = (resp.text or "")[:200].replace("\n", " ")
        raise PgaTourError(
            f"non-JSON response from {context} "
            f"(status={resp.status_code}): {snippet!r}"
        ) from e


def graphql_request(
    operation_name: str,
    variables: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Make a GraphQL request to the PGA Tour API."""
    query = _read_query(operation_name)
    payload = {
        "query": query,
        "variables": variables or {},
        "operationName": operation_name,
    }
    cache_key = {"operation": operation_name, "variables": variables or {}}
    cached = _cache_read("graphql", cache_key)
    if cached is not _CACHE_MISS:
        logger.debug("pga_tour_api graphql cache hit -> %s", operation_name)
        return cached
    if _is_verbose():
        logger.info("pga_tour_api graphql -> %s vars=%s", operation_name, variables)
    else:
        logger.debug("pga_tour_api graphql -> %s vars=%s", operation_name, variables)

    context = f"GraphQL {operation_name}"
    resp = _request_with_retry(
        "POST", GRAPHQL_URL, json_body=payload, context=context,
    )

    if resp.status_code >= 400:
        snippet = (resp.text or "")[:200].replace("\n", " ")
        raise PgaTourError(
            f"{context} failed (status={resp.status_code}): {snippet!r}"
        )

    body = _parse_json(resp, context)

    if isinstance(body, dict) and body.get("errors"):
        msgs = "; ".join(
            e.get("message", "") for e in body["errors"] if isinstance(e, dict)
        )
        raise PgaTourError(f"PGA Tour GraphQL error ({operation_name}): {msgs}")

    result = body.get("data", {}) if isinstance(body, dict) else {}
    _cache_write("graphql", cache_key, result)
    return result


def rest_request(path: str) -> Any:
    """Make a REST GET request to the PGA Tour data API."""
    url = f"{REST_URL}/{path}"
    if _is_verbose():
        logger.info("pga_tour_api rest -> %s", path)
    else:
        logger.debug("pga_tour_api rest -> %s", path)

    context = f"REST {path}"
    cached = _cache_read("rest", path)
    if cached is not _CACHE_MISS:
        logger.debug("pga_tour_api rest cache hit -> %s", path)
        return cached
    resp = _request_with_retry("GET", url, context=context)

    if resp.status_code >= 400:
        snippet = (resp.text or "")[:200].replace("\n", " ")
        raise PgaTourError(
            f"{context} failed (status={resp.status_code}): {snippet!r}"
        )

    result = _parse_json(resp, context)
    _cache_write("rest", path, result)
    return result


def config_request(path: str) -> Any:
    """GET a JSON document from the PGA Tour orchestrator-config host.

    Used for ``web-config`` (this week's tournament IDs) and the other
    small config documents the frontend reads from the same origin.
    """
    url = f"{CONFIG_URL}/{path.lstrip('/')}"
    if _is_verbose():
        logger.info("pga_tour_api config -> %s", path)
    else:
        logger.debug("pga_tour_api config -> %s", path)

    context = f"CONFIG {path}"
    cached = _cache_read("config", path)
    if cached is not _CACHE_MISS:
        logger.debug("pga_tour_api config cache hit -> %s", path)
        return cached
    resp = _request_with_retry("GET", url, context=context)

    if resp.status_code >= 400:
        snippet = (resp.text or "")[:200].replace("\n", " ")
        raise PgaTourError(
            f"{context} failed (status={resp.status_code}): {snippet!r}"
        )

    result = _parse_json(resp, context)
    _cache_write("config", path, result)
    return result


def decompress_payload(payload: str) -> Any:
    """Decode a base64+gzip compressed payload from the API.

    Validates input and surfaces a clear error for each failure step
    (base64 decode, gunzip, JSON parse) instead of cryptic C-level
    messages.
    """
    if not isinstance(payload, str) or not payload:
        raise PgaTourError("decompress_payload: payload must be a non-empty string")
    try:
        raw = base64.b64decode(payload, validate=True)
    except (binascii.Error, ValueError) as e:
        raise PgaTourError(f"failed to base64-decode payload: {e}") from e
    try:
        decompressed = gzip.decompress(raw)
    except (OSError, EOFError) as e:
        raise PgaTourError(f"failed to gunzip payload: {e}") from e
    try:
        return json.loads(decompressed)
    except json.JSONDecodeError as e:
        raise PgaTourError(f"failed to parse decompressed payload: {e}") from e
