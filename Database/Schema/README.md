# GolfDB+ PostgreSQL migrations

Apply the canonical UUID-based migration set with PostgreSQL 15+ and `psql`.

```bash
psql "$DATABASE_URL" -f Database/Schema/install.psql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f Database/Queries/intake.sql -f Database/Queries/promote.sql \
  -f Database/Queries/read.sql -f Database/Tests/incoming_data.sql
```

| Order | Migration | Purpose |
| --- | --- | --- |
| 1 | [UUID foundation](001_golfdb_foundation.sql) | Canonical player, course, event, tour, season and content tables. |
| 2 | [Core reference](002_core_foundations.sql) | Shared lookup vocabulary, units, sources and optional reference links. |
| 3 | [Incoming data](003_incoming_data.sql) | Staging, provider IDs, facts, outputs and reporting views. |
| 4 | [Query views](004_query_views.sql) | Player par scoring and event and intake coverage. |
| 5 | [Performance and statistics](005_performance_statistics.sql) | Scoring views, player round and shot tracking, and versioned predictability outputs. |

Run the same installer for a database already on the UUID foundation. It adds tables and seeds mappings from the legacy columns. Future writes use the mapping tables. Review any provider IDs assigned independently in older pipelines before import. Installer roles need schema creation, table alteration and extension permissions where applicable.

The original bigint Shot Tracker design is a separate target. Its historical design notes are [here](../Data-Catalog/SHOT-TRACKER-LEGACY.md). `001_ingest.sql`, `002_tours_season.sql`, `003_reference_mapping_ids`, `004_admin_stats.sql`, `005_admin_dashboard.sql`, `core.sql` and `example.sql` are historical standalone scripts or design fragments outside the canonical install. The raw reference dictionary is research material containing prose and examples.

## Ingestion transaction

For the checked-in source snapshots, verify the [source inventory and checksums](../../Data/Source-Files/README.md) before staging. This workflow describes promotion requirements. The migration installer creates the schema without importing the Parquet or TSV files.

1. Archive original bytes privately and calculate SHA-256. Register the retrieval with the operation, stable request key and observation timestamp.
2. Stage normalized candidates with stable record keys. Reuse the same observation timestamp on retry. A distinct retrieval keeps a distinct observation even if bytes match.
3. Resolve source identifiers before promotion. Create reviewed canonical entities and first mappings transactionally. Roll back on mapping conflicts. For pending work, lock the staged record with `SELECT ... FOR UPDATE` before applying normalized writes.
4. Preserve and quarantine unresolved IDs, unknown units and invalid setup rows. Treat conflicting retry inputs as errors when a prepared statement returns zero rows. A quarantined row can be put back in the pending queue after review in an explicit transaction.
5. Write accepted facts and mark records accepted in the same transaction. Use complete current-row inputs, because these upserts replace the current row when evidence is newer. For immutable facts, an identical retry retains the original. Submit corrections under a new observation or model run.
6. Promote complete event publications together. Use their exact observation IDs for reads. Keep a partially resolved batch staged until the gaps are reconciled.

See the [catalog and ERD](../Data-Catalog/README.md) for the full inventory and source-to-table mapping.

## 2026 performance and scoring

The [performance and statistics migration](005_performance_statistics.sql) adds the following read models and input tables. PostgreSQL schema names are lowercase.

| Object | Grain and source |
| --- | --- |
| `statistic.player_registry` | Canonical player UUID, text PGA TOUR ID and the `analytics.player_info` profile. The 2026 roster uses the union of player IDs in the checked-in tee times, shots and player directory. |
| `statistic.results_scoring_event_basic` | Player, event and official publication, with available rounds 1–4. Course is the event's primary venue. |
| `statistic.results_events_positioning` | Player, event and official publication, including rank display, earnings currency and FedExCup points. |
| `statistic.results_scoring_round` | Player and event round, with actual round venue and available tee time. The date range is the event date range. |
| `statistic.course_scorecard` | Event, course, round setup and hole. Nine- and 18-hole totals require the relevant complete setup. |
| `performance.player_tracker_round` | One row per scored player round, with separate columns for holes 1–18 and front/back totals. |
| `performance.player_tracker_round_totals` | Scored player round, with known-hole counts and FIR/GIR denominators. The one-putt and three-putt counts use exact values. |
| `performance.player_tracker_shot_tourcast` | One reviewed source shot identity in its event and player round. Use feet for putt length, yards for other shot lengths and pin distances, mph for swing speed and feet for apex. |
| `performance.shot_performance_predictability_output` | One shot, model version and evidence cutoff. Stores modeled zone, percentile interval, weather and difficulty scores, factors, projected outcomes and probability buckets. |

Filter season-specific results with `season_id = '2026-PGA'`. Round and event scores are read from the canonical scoring tables. Use the publication ID to choose an official result revision. Preserve nulls for unknown observations. Store reviewed FIR, GIR, proximity and putts in `performance.player_hole_metrics`. In round totals, the FIR/GIR available counts represent known indicators, and the putt total is a sum of measured holes. Review coverage counts before comparing rounds.

The [2026 sources](../../Data/Source-Files/README.md) do not establish every requested fact. Preserve repeated source shot keys in staging pending disambiguation. The snapshot does not establish club selection, swing plane, shot shape, hole handicap, weather impact or player wellness for every shot. Use independently verified sources for those fields. Official finish, earnings and points come from the official result publication.

### Shot model display

Open [shot-predictability.html](../Admin/shot-predictability.html) in a browser. Save the JSON value from the query below as a file and load it with the page's file picker. Add event, round or player predicates to narrow the export.

```sql
SELECT COALESCE(jsonb_agg(to_jsonb(s) ORDER BY hole_number, shot_id, as_of), '[]'::jsonb)
FROM performance.shot_predictability_display s
WHERE s.event_id = '<event UUID>'::uuid;
```

The display plots shot positions in the named coordinate frame. A modeled zone uses a Polygon geometry with a `coordinate_frame` field matching the shot. The graphic is a coordinate plot with no course basemap. The dashed line joins the two recorded endpoints. The sidebar shows the normalized strokes-gained indicators and their difference in percentage points.

The three probability buckets are mutually exclusive and sum to one when populated. Forecast impact and difficulty use separate 0–10 scores. Difficulty 0 is reserved for a guaranteed top-quality outcome and 10 rules out the perfect outcome. Percentiles describe the modeled quality range on a 0–100 scale. A calibrated model must supply probabilities, percentile bands, reliability, shot quality and strokes-gained estimates before the panel can show them. The schema and display do not generate predictions.
