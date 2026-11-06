# GolfDB+ Custom Products

| Section | Initial modules | Future outputs |
|---|---|---|
| Data Entry | PlayerDB, EventDB, CourseDB, import queue, cleaning workbench, catalog, source/asset browser, SQL/full-text query console | scheduled ingestion |
| Stats & Metrics | player skill and shot breakdown, event/round/hole leaderboards, course/hole difficulty, rankings | percentile comparisons, derived metrics and history |
| Models | feature registry, player-course match, expected scoring, shot outcome, putting/green modeling | simulations, forecasts, explanations and backtests |

## Navigation routes (proposed)
- /data-entry/players, /data-entry/events, /data-entry/courses
- /data-entry/catalog, /data-entry/cleaning, /data-entry/queries, /data-entry/assets
- /stats/players, /stats/events, /stats/courses
- /models/features, /models/experiments, /models/predictions

## Build order
1. Canonical IDs + provider mappings + schema validation.
2. Asset naming, event document manifest and reviewed downloads.
3. Full-text indexing with entity resolution and source timestamps.
4. Stats/metrics calculation engine and dashboards.
5. Predictive model feature store and as-of backtesting.

**Scope:** This folder defines product requirements; the existing repository does not yet contain a runnable frontend app. Navigation is not represented as implemented UI.
