# Changelog

## [Unreleased]

- Add raw and normalized historical tournament/player odds wrappers.
- Preserve upstream provider and availability messages when historical markets
  are empty instead of presenting unavailable data as populated rows.

## 0.3.6 — 2026-09-25

- Add structured editorial Power Rankings and Expert Picks wrappers using article content-fragment paths.
- Verify live responses with 15 Power Rankings rows and five Expert Picks rows.

## 0.3.5 — 2026-09-24

- Add verified team-stroke-play leaderboard and cup team roster functions.
- Keep match-play leaderboard as a raw documented operation pending a populated event verification.

## 0.3.3 — 2026-09-24

- Add DP World Tour Race to Dubai PGA TOUR eligibility standings (ranking ID 2700).

## 0.3.2 — 2026-09-24

- Add PGA TOUR University rankings and total-points operations with season/week filters.
- Preserve player event histories, source headers and navigation metadata.

## 0.3.0 — 2026-09-24

- Add raw and normalized scorecard statistics, full course/hole rankings, record catalogue and record tables.
- Add searchable record catalogue documentation; preserve source values and selector metadata.
- Bundle four more GraphQL operations; 43 convenience functions (36 DataFrames), 48 raw methods, 106 offline tests.
- Live smoke checks returned 103 scorecard-stat rows, 41 courses, 738 holes, 282 record IDs and 86 rows for record 2-1-11. Dataset sizes are snapshots, not coverage guarantees.
- Warning: upstream record tables may contain anomalous or incomplete entries; values are not independently corrected.

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/).

## 0.3.7 — 2026-09-25

- Add scheduled live smoke coverage for playoff, team-stroke, match-play and
  cup-team endpoints.
- Add normalized match-play leaderboard support, live-verified against the 2023
  WGC-Dell Technologies Match Play (`R2023470`).
- Add an opt-in JSON response cache for completed and historical reads, with
  TTL controls, cache-failure isolation and offline tests.
- Release the project-specific code under the MIT License and package the
  third-party notices in both distribution formats.

## 0.3.6 — 2026-09-25

- Add structured editorial Power Rankings and Expert Picks wrappers using
  article content-fragment paths.
- Verify live responses with 15 Power Rankings rows and five Expert Picks rows.

## [Unreleased]

### Planned

- Publish the documentation site when repository visibility permits.
- Add type-safe response models as an optional interface.

## [0.2.0] - 2026-09-23

### Added

- Normalized pandas DataFrame interface with 39 `pga_*` functions.
- Importable `STAT_IDS` catalog with 467 discovered statistics.
- Multi-stat and multi-season batching for `pga_stats`.
- Request logging, bounded retries, public-key override, and transport errors.
- 43 offline API fixtures and 88 passing tests.
- Linux/macOS CI across Python 3.9–3.13.
- Expanded documentation, troubleshooting, schemas, and complete API reference.

### Changed

- Moved the original object-oriented raw client to `pga_tour_api.raw` while
  retaining `from pga_tour_api import PgaApi` compatibility.

## [0.1.0] - 2026-09-23

### Added

- Initial raw client, endpoint catalog, GraphQL documents, validation report,
  and local MkDocs site.
