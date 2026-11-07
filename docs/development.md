# Development and testing

## Local setup

```bash
python -m venv .venv
. .venv/bin/activate
pip install -e ".[dev]"
pytest -ra
mkdocs serve
```

## Offline fixtures

The test suite contains 43 captured or synthetic JSON fixtures covering the
GraphQL, REST, configuration, compressed-payload, parsing, and empty-result
paths. Tests mock the transport layer and therefore do not depend on PGA TOUR
availability.

## Continuous integration

Every push and pull request runs the suite on:

- Ubuntu and macOS
- Python 3.9, 3.10, 3.11, 3.12, and 3.13

The documentation workflow separately performs a strict build and publishes
the static site to GitHub Pages.

## Adding an operation

1. Add the complete GraphQL document to `src/pga_tour_api/graphql/`.
2. Add a thin normalized wrapper to `client.py` or a raw method to `raw.py`.
3. Capture a sanitized fixture.
4. Test success, empty data, malformed data, and transport failures.
5. Add the operation to the reference and changelog.

## Versioning

Versions follow semantic versioning. Because the upstream interface is
unsupported, an upstream-only schema break may require a patch release even
when our public Python signatures do not change.
