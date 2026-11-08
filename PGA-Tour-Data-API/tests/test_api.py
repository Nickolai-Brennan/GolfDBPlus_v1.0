"""Tests for the transport layer (`pga_tour_api._api`)."""

from __future__ import annotations

import base64
import gzip
import json
import os

import pytest
import httpx

from pga_tour_api import _api
from pga_tour_api._api import PgaTourError, _api_key, _is_verbose, decompress_payload


def test_api_key_default(monkeypatch):
    monkeypatch.delenv("PGA_API_KEY", raising=False)
    assert _api_key() == _api._DEFAULT_API_KEY


def test_api_key_env_override(monkeypatch):
    monkeypatch.setenv("PGA_API_KEY", "rotated-key-123")
    assert _api_key() == "rotated-key-123"


def test_api_key_empty_env_falls_back(monkeypatch):
    monkeypatch.setenv("PGA_API_KEY", "")
    assert _api_key() == _api._DEFAULT_API_KEY


@pytest.mark.parametrize("val,expected", [
    ("", False), ("0", False), ("false", False), ("no", False), ("off", False),
    ("FALSE", False), ("1", True), ("true", True), ("yes", True), ("anything", True),
])
def test_is_verbose(monkeypatch, val, expected):
    monkeypatch.setenv("PGATOUR_VERBOSE", val)
    assert _is_verbose() is expected


def test_decompress_roundtrip():
    original = {"hello": "world", "n": [1, 2, 3]}
    payload = base64.b64encode(gzip.compress(json.dumps(original).encode())).decode()
    assert decompress_payload(payload) == original


def test_decompress_rejects_empty():
    with pytest.raises(PgaTourError, match="non-empty"):
        decompress_payload("")


def test_decompress_rejects_non_string():
    with pytest.raises(PgaTourError, match="non-empty"):
        decompress_payload(None)  # type: ignore[arg-type]


def test_decompress_invalid_base64():
    with pytest.raises(PgaTourError, match="base64"):
        decompress_payload("@@@@@@@@@@@@@@@@@@@")


def test_decompress_valid_base64_not_gzip():
    payload = base64.b64encode(b"plaintext, not gzipped").decode()
    with pytest.raises(PgaTourError, match="gunzip"):
        decompress_payload(payload)


def test_decompress_valid_gzip_not_json():
    payload = base64.b64encode(gzip.compress(b"not-json")).decode()
    with pytest.raises(PgaTourError, match="parse"):
        decompress_payload(payload)


def test_graphql_cache_is_opt_in(monkeypatch, tmp_path):
    calls = []

    def fake_request(method, url, *, json_body=None, context):
        calls.append((method, url, json_body, context))
        return httpx.Response(200, json={"data": {"value": len(calls)}})

    monkeypatch.setenv("PGATOUR_CACHE_DIR", str(tmp_path))
    monkeypatch.setattr(_api, "_request_with_retry", fake_request)

    first = _api.graphql_request("StatDetails", {"statId": "02675"})
    second = _api.graphql_request("StatDetails", {"statId": "02675"})

    assert first == {"value": 1}
    assert second == first
    assert len(calls) == 1


def test_cache_ttl_zero_bypasses_cache(monkeypatch, tmp_path):
    calls = []

    def fake_request(method, url, *, json_body=None, context):
        calls.append(context)
        return httpx.Response(200, json={"data": {"value": len(calls)}})

    monkeypatch.setenv("PGATOUR_CACHE_DIR", str(tmp_path))
    monkeypatch.setenv("PGATOUR_CACHE_TTL", "0")
    monkeypatch.setattr(_api, "_request_with_retry", fake_request)

    assert _api.graphql_request("StatDetails", {"statId": "02675"}) == {"value": 1}
    assert _api.graphql_request("StatDetails", {"statId": "02675"}) == {"value": 2}
    assert len(calls) == 2
