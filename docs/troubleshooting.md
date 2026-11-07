# Troubleshooting

## The API key stopped working

The bundled key is a public browser key and can rotate. Capture the current
value from an ordinary `pgatour.com` GraphQL request and override it:

```bash
export PGA_API_KEY="replacement-public-browser-key"
```

Never put personal credentials in this variable.

## A call returns an empty DataFrame

Empty data is normal when an event is completed, has not begun, or does not
support a feature. Odds, coverage, TOURCAST videos, radar, and current player
status are particularly time- and event-dependent.

## A GraphQL response is not JSON

CDN and upstream failures sometimes return an HTML error page. The client
raises `PgaTourError` with the operation, status, and a short response preview.
Retry only transient `408`, `429`, and `5xx` responses.

## Enable request logging

```bash
export PGATOUR_VERBOSE=1
```

Or configure the package logger directly:

```python
import logging

logging.getLogger("pga_tour_api").setLevel(logging.DEBUG)
```

## Cache completed or historical reads

Caching is disabled unless explicitly enabled. To cache responses locally:

```bash
export PGATOUR_CACHE_DIR=".cache/pga-tour"
export PGATOUR_CACHE_TTL="86400"
```

Set `PGATOUR_CACHE_TTL=0` to bypass the cache. The cache is keyed by operation,
variables, and REST/config path; failed or malformed responses are never
cached.

## Tournament IDs

Use the full ID for most calls—for example, `R2026030`. Video queries can use a
numeric event code in some contexts. Discover current IDs with
`pga_current_tournament()` and historical IDs with `pga_schedule()`.

## Report a schema change

Record the operation name, variables, status code, and sanitized response
shape. Do not post API keys, cookies, personal identifiers, or account data.
