# PGA TOUR unofficial API reference

Reverse-engineered field guide to the public browser-facing data services used
by `pgatour.com`. This is an unofficial, best-effort snapshot verified on
2026-09-23. It is not affiliated with or supported by PGA TOUR.

The result is closer to the NHL API reference than it first appears: the site
has stable IDs, machine-readable JSON, a GraphQL endpoint, REST endpoints, and
a small configuration service. The main difference is that PGA TOUR does not
publish a compatibility contract, and several large responses are compressed.

## What is included

- 44 complete GraphQL query documents in [`graphql/`](graphql/)
- REST and configuration routes
- 56 convenience functions: 49 return pandas DataFrames; seven return a string, dictionary, or raw JSON
- A raw object-oriented client preserving upstream response structures
- A machine-readable endpoint manifest
- An importable catalog and CSV lookup of 467 PGA TOUR stat IDs
- A live validation report covering 38 useful operations
- 43 offline fixtures and 115 automated tests
- Cross-platform CI for Python 3.9–3.13

See [`ENDPOINTS.md`](ENDPOINTS.md) for the route catalog and variable shapes.

See the [expansion roadmap](docs/roadmap.md) for additional data discovered on
the PGA TOUR website, live verification results, and proposed implementation
priorities. The first three priorities are implemented; later items remain planned.

## Service map

| Surface | Base URL | Role |
|---|---|---|
| GraphQL | `https://orchestrator.pgatour.com/graphql` | Leaderboards, scorecards, shots, stats, fields, standings, weather, content |
| REST | `https://data-api.pgatour.com` | Players, schedules, profiles, results, odds, selected content |
| Config | `https://orchestrator-config.pgatour.com` | Current/default tournament IDs and active season numbers |
| HTML fallback | `https://www.pgatour.com/tournaments/...` | Server-rendered tables, JSON-LD, and Next.js hydration data |

## Quick start

Install the repository directly:

```bash
pip install git+https://github.com/rubenviolinha/pga-tour-unofficial-api.git
```

```python
import pga_tour_api as pga

tournament_id = pga.pga_current_tournament("R")
leaderboard = pga.pga_leaderboard(tournament_id)
schedule = pga.pga_schedule(2026, "R")
players = pga.pga_players("R")
sg_total = pga.pga_stats("02675", 2026, "R")
```

Most functions return normalized pandas DataFrames; the documented return type
for each function is in the API reference. For upstream response structures:

```python
from pga_tour_api import PgaApi

api = PgaApi()
raw_leaderboard = api.leaderboard(api.current_tournament())
```

The native documentation source lives in [`docs/`](docs/). GitHub Actions
builds and publishes the [documentation site](https://rubenviolinha.github.io/pga-tour-unofficial-api/)
through GitHub Pages on every push to `main`.

## Direct GraphQL request

GraphQL calls are JSON `POST` requests. The browser sends a public frontend
key in `x-api-key`; it is not a user credential, but it can rotate. The example
client contains the value observed on the verification date and lets
`PGA_API_KEY` override it.

```python
from pga_tour_api import PgaApi

api = PgaApi()
response = api.graphql(
    "LeaderboardCompressedV3",
    {"leaderboardCompressedV3Id": "R2026030"},
)
leaderboard = api.decompress(
    response["leaderboardCompressedV3"]["payload"]
)
```

The usual headers are:

```http
Content-Type: application/json
Accept: application/graphql-response+json, application/json
x-api-key: <public frontend key>
x-pgat-platform: web
Origin: https://www.pgatour.com
Referer: https://www.pgatour.com/
```

## Compressed payloads

Operations containing `Compressed` return a `payload` string encoded as:

```text
JSON -> gzip -> base64
```

Decode it in Python with:

```python
import base64, gzip, json

decoded = json.loads(gzip.decompress(base64.b64decode(payload)))
```

Known compressed operations include leaderboard, current leaders, scorecard,
tee times, shot details, odds-to-win, and generic content.

## Identifiers

Tournament IDs combine a tour prefix, season, and event code. Examples:

- `R2026030` — PGA TOUR, 2026, event `030`
- `S2026616` — PGA TOUR Champions
- `H2026094` — Korn Ferry Tour
- `Y2026008` — PGA TOUR Americas

Tour codes:

| Code | Tour |
|---|---|
| `R` | PGA TOUR |
| `S` | PGA TOUR Champions |
| `H` | Korn Ferry Tour |
| `Y` | PGA TOUR Americas |

Player IDs are numeric strings, such as `59095`. Stat IDs are strings and may
have significant leading zeroes, such as `02675`; do not parse them as numbers.

## High-value data

The API currently exposes:

- Full and abbreviated live leaderboards
- Hole-by-hole field scoring
- Player scorecards
- Shot-level play-by-play, coordinates, distances, and radar fields when available
- Tee groups and start tees
- Tournament fields, alternates, withdrawals, OWGR, current form, and course fit
- Season schedules, tournament metadata, past results, and weather
- 400+ statistical categories and player rankings
- FedExCup, signature-event, and priority rankings
- Player directory, profiles, biographies, career summaries, results, and 100+ profile stats
- Broadcast coverage, news, highlights, TOURCAST clips, and betting markets when active

## HTML fallback

When an API route changes, tournament leaderboard pages remain useful. Their
HTML contains:

- `script#leaderboard-seo-data` — JSON-LD/CSVW leaderboard data
- `script#__NEXT_DATA__` — Next.js hydration state with tournament metadata
- A server-rendered leaderboard table

The fallback is less complete than GraphQL but often survives API migrations.

## Stability and responsible use

- This is an internal website interface, not a supported public API.
- Cache historical results and avoid polling static data.
- The included client defaults to one request per second and retries only
  transient failures.
- Respect `https://www.pgatour.com/robots.txt`, site terms, and data licensing.
- Do not bypass authentication or access controls. This reference covers only
  data already delivered to ordinary public browser sessions.
- Live odds, coverage, videos, and player tournament status can correctly be
  empty outside their active window.

## License

The project-specific code is released under the [MIT License](LICENSE).
Third-party material adapted from `pgatourPY` retains its separate notice in
[`NOTICE.md`](NOTICE.md) and the original license text in
[`LICENSES/pgatourPY-MIT.txt`](LICENSES/pgatourPY-MIT.txt). The license covers
the software, not PGA TOUR trademarks, website content, or data-redistribution
rights.

## Provenance

The route inventory was verified against live PGA TOUR responses. The
normalized DataFrame layer, query documents, stat catalog, fixtures, and parts
of the tests were adapted from the MIT-licensed `WalrusQuant/pgatourPY`
project. See [`NOTICE.md`](NOTICE.md) and
[`LICENSES/pgatourPY-MIT.txt`](LICENSES/pgatourPY-MIT.txt).

Research and attribution references:

- <https://github.com/WalrusQuant/pgatourPY>
- <https://walrusquant.github.io/pgatourPY/reference/>
- <https://www.pgatour.com/robots.txt>
- <https://github.com/Zmalski/NHL-API-Reference>
