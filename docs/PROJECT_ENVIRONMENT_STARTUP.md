# GolfDB+ — Project Environment & Startup Guide

**Document:** `docs/PROJECT_ENVIRONMENT_STARTUP.md`  
**Project:** [GolfDBPlus_v1.0](https://github.com/Nickolai-Brennan/GolfDBPlus_v1.0)  
**Status:** Architecture decision and workstation setup guide, not proof of installed software  
**Updated:** 2026-11-07
**Target developer:** Solo Windows operator; commands use PowerShell unless marked otherwise

## 1. Product boundaries

GolfDB+ has three primary application sections:

1. **Data Entry:** Players, Events, Courses; data catalog; import; data cleaning; document assets; source-ID mapping; data queries and full-text search.
2. **Stats & Metrics:** Shot/round/event/player/course statistics, rankings, percentiles, time-stamped measurements and interactive mapping.
3. **Models:** Model datasets, historical-as-of feature engineering, simulations, predictive analytics, model evaluation and evidence attribution.

The primary master entity registry contains `players_tracking`, `courses`, `events`, `tours`, `seasons` and related source and document tables. GolfDB+ UUIDs are authoritative; DataGolf/PGA TOUR/ESPN/CBS/RickRunGood IDs are attributes for matching external records. A tour is one of `PGA`, `DP`, `LIV`, `SEN`, `ASIA`; season format is `YYYY-TOUR`, e.g. `2026-PGA`.

**Repository audit:** At documentation time the repository contains SQL foundation schema, collector/indexing Python scripts, asset placeholders, data catalog, product scope docs and operator runbook. It **does not yet contain an implemented React frontend, a FastAPI server, application package manifests, an Alembic migration setup, a Docker Compose stack, CI test suite or an operational deployed website**. All tools below are either existing, recommended or deferred as explicitly indicated.

The [page inventory](PAGE_INVENTORY.md) covers the separate static demo and planned application pages. See the [database guide](../Database/Design/readme.md) for the core dictionary migration.

## 2. Architecture overview

```mermaid
flowchart TD
    S[PGA TOUR / ShotLink / DataGolf / permitted news sources] --> I[Python collectors / authorized adapters]
    I --> RAW[Private original document & object storage]
    I --> STG[Validated import staging & provenance]
    STG --> DB[(PostgreSQL canonical entities / stats / content)]
    RAW --> IDX[Document extraction / full-text indexing]
    IDX --> DB
    DB <--> API[Python FastAPI + Pydantic + SQLAlchemy]
    API <--> UI[React + TypeScript + Vite]
    DB --> FEAT[As-of features / Python statistical models]
    FEAT --> DB
    FEAT --> API
```

Architecture principles: separate external source payloads from normalized data; preserve raw originals and checksums; do not expose restricted source files publicly; preserve source and publication timestamps; distinguish measured values from inferred values; version models/transformations; prevent historical lookahead.

## 3. Decision register: programming languages

| Language/format | Status | Use |
| --- | --- | --- |
| Python 3.11+ | Existing scripts; recommended server | Ingest, cleaning, API, models, tests |
| SQL (PostgreSQL 15+) | Existing schema | Core database, queries and indexes |
| TypeScript | Recommended, not implemented | Frontend UI and typed API clients |
| JavaScript | Indirect through TypeScript/Node | Frontend runtime, libraries/tooling |
| HTML/CSS | Recommended, not implemented | Semantic UI and styling |
| JSON / JSONL | Existing examples | Source payloads, content indexing, API |
| CSV | Existing examples | Staging imports and exports |
| Parquet | Recommended | Large shot-event/measurement datasets |
| YAML | Recommended | Compose, CI and configuration |
| Markdown | Existing | Catalog, startup guide, runbooks |

Do **not** adopt GraphQL as a database: GraphQL is a query/API language, not a storage engine. PostgreSQL is the record store; REST/JSON via FastAPI is the first API. A GraphQL gateway can be considered later when client query composition warrants it. No separate MongoDB or Neo4j service is required for phase 1.

## 4. Apps, installs and services

| App/tool | Role | Status | Required for first local milestone? |
| --- | --- | --- | --- |
| Visual Studio Code | IDE, Python/TS debugging | Recommended | Yes |
| Git | Version control | GitHub repo exists; local Git installation not verified | Yes |
| GitHub | Repository, issues, PR, CI | Connected repository verified | Yes |
| Python 3.11+ | Core ETL, API, analytics | Python collector scripts exist; local runtime unverified | Yes |
| Node.js active LTS + npm | React/Vite toolchain | Recommended | Yes for future UI |
| PostgreSQL 15+ | Canonical relational store | SQL file exists, database runtime unverified | Yes |
| Docker Desktop + Compose | Repeatable local DB/storage/worker services | Recommended, not configured | Recommended |
| pgAdmin / DBeaver | SQL inspection and admin | Optional | No |
| Postman / Bruno / HTTPie | Test HTTP endpoints | Optional | No |
| Playwright | End-to-end UI tests and permitted browser adapters | Planned | Later |
| MinIO locally / private S3-compatible storage in production | Event attachments, media and raw files | Planned | Local filesystem sufficient initially |
| GitHub Actions | CI tests / safe schedules | Planned | After app scaffold |
| Redis / Celery | Distributed task queues | Deferred | No |
| OpenSearch / pgvector | Advanced search / retrieval | Deferred | No |
| Vercel (frontend) + managed Python host + managed Postgres | Example production deployment option | Not selected or configured | No |

Download approved software from the official vendor sites; pin exact reproducible versions in package-lock/uv.lock or requirements and release documentation before production. Avoid unverified 'latest' claims.

### IDE extension suggestions
- Python and Pylance (Microsoft)
- Ruff Python linter
- ESLint, Prettier
- Docker
- PostgreSQL or SQLTools
- GitHub Pull Requests and Issues

### Recommended code libraries, not yet installed
- Frontend: React, Vite, TypeScript, React Router, TanStack Query, Tailwind CSS, shadcn/ui, TanStack Table, Apache ECharts or Plotly.
- Spatial/3D: MapLibre GL JS + deck.gl for map layers; Three.js only if green-mesh scenes actually require full 3D rendering.
- Backend: FastAPI, Uvicorn, Pydantic, SQLAlchemy, psycopg, Alembic.
- Data: pandas, polars, pyarrow, numpy, SciPy, scikit-learn, statsmodels.
- Document parsing: pypdf, openpyxl, BeautifulSoup (verify each source's terms before retrieval).
- Quality: pytest, ruff, mypy, Vitest, Playwright.

Keep initial dependencies narrow; introduce additional packages only in the phase that uses them.

## 5. External integrations inventory

| Source | Intended data | Integration maturity | Credentials / caveats |
| --- | --- | --- | --- |
| [PGA TOUR Media](https://pgatourmedia.pgatourhq.com/) | Event documents, notes, transcript landing pages | Python HTML-link discovery script exists | Permissions and source-specific validation required |
| [World Wide Technology Championship 2026 event page](https://pgatourmedia.pgatourhq.com/tours/2026/pgatour/worldwidetechnologychampionship) | Event attachment discovery | Example source in project | Not a verified all-files download |
| [ShotLink](https://shotlink.com/) | Shot data and reporting information | Planned source adapter | Access/rights verification |
| [ShotLink Reports](https://reports.shotlink.com/?tc=r) | Season-event report documents | Browser-selector adapter not built | Do not bypass authentication or automation controls |
| DataGolf | Player/course/event source IDs, performance datasets | Schema fields planned | API access/key/usage terms TBD |
| PGA TOUR event/shot feeds | Tourcast shots, leaderboards, tee times and profiles | Relevant to shot tracking, not wired into this repo | Confirm authorization, source stability |
| ESPN | Player external IDs and permissible data | Mapping only | Adapter/API TBD |
| CBS Sports | Player external IDs and permissible data | Mapping only | Adapter/API TBD |
| RickRunGood | Player ID associations | Mapping only | Licensing/access TBD |
| Official transcripts / approved editorial feeds | Content date, title, ID, URL, type, matched player/event/course | Script URL register and offline indexer foundation | Respect copyrights, licenses and publication dates |
| GitHub | Source control, issues, PRs, CI | Repo active | Use personal auth locally; never store tokens in git |

**Do not assume an unofficial endpoint is a supported production API.** Check provider authorization, quotas, credentials and changing response schemas per adapter. The `content_index.py` script processes supplied JSONL offline; it does **not** search the web itself.

## 6. Repository structure: actual and proposed

Legend: `[existing]` verified in repository; `[proposed]` planned, not created by this guide.

```text
GolfDBPlus_v1.0/
├── Assets/                         [existing; placeholder tree, asset README]
│   ├── Events/
│   ├── Players/
│   └── Courses/
├── Data-Catalog/                   [existing]
├── Dev-Actions-Workflows/          [existing]
│   ├── event_collector.py
│   ├── content_index.py
│   ├── RUNBOOK.md
│   └── examples/
├── Custom-Products/               [existing]
├── Design/Database/SQL/
│   ├── 001_golfdb_foundation.sql  [existing]
│   └── 002_core_reference.sql     [existing]
├── docs/
│   └── PROJECT_ENVIRONMENT_STARTUP.md [this guide]
├── frontend/                       [proposed React+TS/Vite]
│   ├── src/features/data-entry/
│   ├── src/features/stats/
│   ├── src/features/models/
│   └── src/lib/api/
├── backend/                        [proposed FastAPI app]
│   ├── app/api/
│   ├── app/db/
│   ├── app/schemas/
│   ├── app/services/
│   └── tests/
├── pipelines/                      [proposed extraction/normalization]
│   ├── adapters/
│   ├── transforms/
│   └── validation/
├── models/                         [proposed modeling code]
├── infra/                          [proposed Compose/deployment configs]
├── .env.example                    [proposed, no secrets]
└── .github/workflows/              [proposed CI]
```

The existing `Assets/Events`, `Assets/Players`, and `Assets/Courses` are not yet uniformly organized with canonical slug+UUID naming. During migration, never replace or delete preexisting assets without inventory.

## 7. Workstation prerequisites — Windows PowerShell

Install Git, Python 3.11+, Node.js active LTS, VS Code, PostgreSQL (or Docker Desktop with Postgres container), and optionally Docker Desktop for more repeatable local services.

Run from a new PowerShell session:

```powershell
# Verify tool availability, not proof of application setup.
git --version
py -3 --version
node --version
npm --version
docker --version
docker compose version
psql --version
```

If Docker or psql is absent, install the corresponding tool or follow the native-PostgreSQL alternative. If a version command fails, correct PATH/install before proceeding.

Clone and inspect:

```powershell
git clone https://github.com/Nickolai-Brennan/GolfDBPlus_v1.0.git
cd GolfDBPlus_v1.0
git status
git branch --show-current
Get-ChildItem
```

Create Python virtual environment and verify existing scripts:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python --version
python Dev-Actions-Workflows/event_collector.py --help
python Dev-Actions-Workflows/content_index.py --help
```

If execution policy blocks activation, invoke `.venv\Scripts\python.exe` explicitly; do not weaken system-wide security settings.

Offline ingestion smoke test (uses example placeholders, **not real GolfDB+ UUID mappings**):

```powershell
python Dev-Actions-Workflows/content_index.py `
  --input Dev-Actions-Workflows/examples/sample_content.jsonl `
  --aliases Dev-Actions-Workflows/examples/aliases.json `
  --out data/staging
Get-Content data/staging/content_items.csv
Get-Content data/staging/content_mentions.csv
```

**Collector dry-run** (requests official HTML, so network access and permissions must be available):

```powershell
python Dev-Actions-Workflows/event_collector.py `
  --url https://pgatourmedia.pgatourhq.com/tours/2026/pgatour/worldwidetechnologychampionship `
  --transcript-url https://tee-scripts.com/pgatour/wwtchampionship-com/ `
  --out Assets/Events/2026-PGA/world-wide-technology-championship
```

By default this discovers HTML links and writes a manifest; it does not download linked attachments. The `--download` flag should only be used after confirming source rights. A dynamic report selector needs another verified adapter.

## 8. PostgreSQL startup

The existing schema uses PostgreSQL `pgcrypto` for UUID creation; it is designed for Postgres 15+.

**Option A — native PostgreSQL.** Create a dedicated local development database/user with least privilege, then apply:

```powershell
# Set this ONLY in the local terminal/session, with your actual development DB values.
$env:DATABASE_URL = "postgresql://golfdb_dev:YOUR_LOCAL_PASSWORD@localhost:5432/golfdb_dev"
psql $env:DATABASE_URL -v ON_ERROR_STOP=1 -f Design/Database/SQL/001_golfdb_foundation.sql
psql $env:DATABASE_URL -v ON_ERROR_STOP=1 -f Design/Database/SQL/002_core_reference.sql
psql $env:DATABASE_URL -c 'SELECT "tourID", tour_name FROM tours ORDER BY "tourID";'
```

**Option B — Docker.** Create a `compose.yaml` in a subsequent implementation step. This guide does not pretend that a Compose file or running database exists today. Use a persistent named volume and never publish database ports broadly in production.

**Database quality gate:** Test schema creation on a fresh empty database and verify constraints, indexes, foreign keys and migrations. A SQL script in Git is not evidence that a database has been provisioned.

## 9. Frontend & backend scaffold (future implementation, not executable as-is)

### React/TypeScript frontend

```powershell
# Scaffold only when approved as the project's chosen frontend architecture.
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install
npm install react-router-dom @tanstack/react-query
npm run dev
```

Proposed first UI paths:
- `/data-entry/players`, `/data-entry/events`, `/data-entry/courses`
- `/data-entry/catalog`, `/data-entry/cleaning`, `/data-entry/queries`, `/data-entry/assets`
- `/stats/players`, `/stats/events`, `/stats/courses`
- `/models/features`, `/models/experiments`, `/models/predictions`

### Python FastAPI backend

```powershell
# From repository root, once backend package is scaffolded.
python -m pip install fastapi "uvicorn[standard]" sqlalchemy "psycopg[binary]" alembic pydantic-settings
# After backend/app/main.py has been created:
python -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

The last command **will fail in the current repository** until `backend/app/main.py` is implemented. Plan early endpoints `GET /health`, `/players`, `/events`, `/courses`, `/documents`, `/search`, `/metrics` and `/models`. Add auth, permission checks, pagination, input validation, consistent errors and audit logs before public deployment.

## 10. Environment variables and secrets

Suggested future `.env.example` contract (illustrative placeholders only):

```dotenv
# Never store real credentials in a tracked example file.
APP_ENV=development
DATABASE_URL=postgresql://golfdb_dev:CHANGE_ME@localhost:5432/golfdb_dev
API_HOST=127.0.0.1
API_PORT=8000
CORS_ORIGINS=http://localhost:5173

# Local filesystem first; replace with private S3-compatible object store.
ASSET_STORAGE_BACKEND=local
ASSET_LOCAL_ROOT=./data/raw
S3_BUCKET=
S3_ENDPOINT=
S3_REGION=
S3_ACCESS_KEY_ID=
S3_SECRET_ACCESS_KEY=

# Only if a provider grants access.
DATAGOLF_API_KEY=
PGATOUR_MEDIA_ACCESS_TOKEN=
SHOTLINK_ACCESS_TOKEN=
CONTENT_SEARCH_API_KEY=

# Future observability/workers.
LOG_LEVEL=INFO
REDIS_URL=
```

Not every source supports API tokens; placeholders do not imply that these providers expose such authentication methods. Use actual provider-supported access patterns. For frontend, expose only non-secret values with `VITE_` prefixes. Maintain `.env` in Git ignore, and deploy secrets with a secret manager or hosting environment settings. Never commit credentials or raw licensed files to this **public** repository.

## 11. Ingestion, content search and model development

### Attachment collector pipeline
```text
select season/event
  -> discover official page/report listings
  -> legal/access check
  -> download authorized original bytes
  -> SHA-256 + manifest + storage path
  -> parse/transcribe permitted content
  -> validate metadata and entity mapping
  -> stage and publish to PostgreSQL
  -> index/feature extraction
```

The existing collector handles plain HTML links for allowlisted hosts. It is not an authenticated browser robot and may miss JavaScript-generated download URLs. The ShotLink Reports workflow must be implemented, tested and authorized separately.

### Content intelligence pipeline
```text
canonical aliases for players/events/courses
  -> approved search provider / RSS / official transcripts
  -> canonical URL + published date + title + source + type
  -> permitted full text or licensed excerpt
  -> dedupe and language normalization
  -> candidate entity mentions
  -> disambiguation and editorial approval
  -> PostgreSQL full-text search / optional semantic retrieval
  -> as-of feature snapshots
  -> reproducible model evaluation
```

The existing `content_index.py` supports local/offline aliases over supplied JSONL and writes staging CSV. It does not fetch articles/search provider APIs, and its sample UUIDs are placeholders. PostgreSQL's existing `content_items.search_vector` is a practical first index; review joins and indexes before adding OpenSearch.

### Modeling stack by maturity
1. **Initial:** pandas/Polars, NumPy, SciPy, statsmodels, scikit-learn; deterministic baselines.
2. **Next:** Gradient boosting (only if measured lift warrants it); explainability, validation, reproducible training runs.
3. **Later:** Time-aware player/course embeddings, spatial 3D green/putt representations, semantic retrieval and simulations.

Separate measured shot data from inferred physics or course slope. Track source quality and uncertainty.

## 12. UI route and service boundaries

| User-facing screen | Backing services | Key persistent entities |
| --- | --- | --- |
| PlayerDB | Entity registry, provider mappings, validation | players_tracking, external IDs |
| EventDB | Tour/season registry, event collector, document catalog | events, seasons, event_documents |
| CourseDB | Course registry, asset metadata, map lookup | courses, assets, eventually holes |
| Import & Cleaning | File ingest, staged rows, deduplication review | raw manifests + staging + audit history |
| Query Studio | Read-only SQL API, full-text search | source IDs, content_items, entity mentions |
| Stats & Metrics | Time-aware calculation engine, cached aggregate queries | shot/round/event derived tables (future) |
| Models | Feature generation, run tracking, evaluation | feature snapshots, model runs (future) |

Use role-based access for writes, raw files and query execution. The public website should not expose arbitrary unrestricted SQL or raw restricted documents.

## 13. Quality, CI/CD and deployment

**Phase 1:** `pytest` for schema fixtures and Python collectors; `ruff` for formatting/lint; migration test in disposable PostgreSQL; document source mocks.  
**Phase 2:** `Vitest` for React logic, `Playwright` for navigation/import smoke tests; API contract tests.  
**Phase 3:** GitHub Actions PR checks, vulnerability scanning, secrets scanning and controlled staging deployment.  
**Phase 4:** Production rollout with database backups, storage lifecycle rules, audit logs, alerting and rollback.  

Recommended deployment split (not yet selected):
- Static React UI: Vercel or equivalent.
- Python API/workers: managed container service supporting scheduled jobs.
- Database: managed PostgreSQL with backups.
- Assets: private S3-compatible object storage with signed authorized access.
- Secrets: cloud secret manager; separate development/staging/production.

Do **not** deploy periodic source downloading until permission, retry/rate limit, robots/API policies and operational costs are validated.

## 14. Ordered startup milestones / acceptance criteria

- [ ] **Environment:** Git, Python, Node, database verified with exact versions recorded.
- [ ] **Source control:** Local clone connected; branch strategy, secrets handling and PR review in place.
- [ ] **Database:** Foundation SQL applies cleanly to empty PostgreSQL; basic entities insert/read; UUID mappings validated.
- [ ] **Data collector:** Offline content-index smoke test passes; approved event page discovered into manifest without leaking files.
- [ ] **API:** FastAPI skeleton, `/health`, first read/write endpoint and error handling.
- [ ] **Frontend:** React app loads; three main navigational sections and player/event/course catalog pages render.
- [ ] **Data quality:** Import rejects invalid nationality codes/season IDs; duplicates and conflicts reviewed.
- [ ] **Source integration:** One authorized end-to-end event ingestion with checksum, manifest and traceable source.
- [ ] **Analytics:** One tested derived metric; stored calculation version and measured vs inferred distinction.
- [ ] **Models:** One baseline with evaluation, as-of cutoff and source/evidence record.
- [ ] **Release:** CI, staging, auth, monitoring, backup and rollback documented and tested.

## 15. Risks and maintenance

- **Source rights:** Discovering links is not permission to store, publish or redistribute files.
- **Source stability:** Providers may change routes, field names and access patterns.
- **Identity collisions:** Same names, alternative spellings, event-season identifiers; external IDs must not replace canonical UUIDs.
- **Temporal leakage:** Backtests must only use evidence available at prediction time.
- **Operational load:** Batch downloads, cache parsed results, cap concurrency and file size, index frequent lookups, partition high-volume shot tables later.
- **Security:** Keep private blobs out of public Git, restrict database privileges, audit administrative actions, rotate keys.
- **Maintenance:** Pin runtime and dependency versions, maintain migrations, run fixture regression tests and check provider adapters routinely.

## Implementation Notes

**Assumptions:** Solo developer using Windows/PowerShell; PostgreSQL+Python+React chosen as the recommended initial architecture; provider integrations require confirmation.  
**Risks:** Existing repo has no runnable app, and provider access may be restricted.  
**Next Steps:** Install prerequisites, verify schema, scaffold backend/frontend, connect first canonical entity endpoint, validate permitted collection.  
**Alternatives:** Native PostgreSQL vs Docker; local filesystem vs S3; Plotly vs ECharts; REST first vs GraphQL gateway later.  
**Performance Considerations:** Keep source ingestion incremental, cache aggregates, normalize identifiers, partition shot-level data at sufficient scale.  
**Maintenance Considerations:** Automated tests, dependency pins, migrations, licenses, manifests, monitoring and documented recovery procedures.
