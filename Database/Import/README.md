# Verified 2026 archive replay

This loader imports regulation course setups from the 2026 snapshot and leaves round 5 course rows in the archive and uses John Deere Classic (`R2026030`) as a scoring and shot replay. It compares every published numeric round score with the sum of 18 unique final-hole scores. The tee-time and course setup records must match the round and venue. Official earnings and points are left null because the archived leaderboard export does not contain those fields.

Tourcast shots require a reconciled round and a unique archive key. All rows in repeated key groups remain in the source. The loader imports physical strokes and excludes penalty/drop records from the shot table. Shot identifiers are scoped to the archive, event, player, and round. Coordinates use the provider's native frame for the venue and hole. The archive's distances are treated as yards and putt travel is converted to feet for the shot table. Unsupported shot attributes stay null.

## Run

Use an isolated GolfDBPlus branch with the [schema installed](../Schema/README.md) and verified PGA TOUR player IDs in the registry. The replay does not create players or change existing canonical facts.

```bash
python -m pip install pandas pyarrow numpy scipy scikit-learn
python Database/Import/prepare_2026_facts.py /tmp/golfdb-verified-2026
python Database/Import/build_2026_sql.py /tmp/golfdb-verified-2026
for batch in /tmp/golfdb-verified-2026/*.sql; do
  psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$batch" || exit
done
```

Batches are ordered by dependency and replay safely for the same source snapshot. Inspect the final counts against `metrics.json`. Run on a review branch if conflicting canonical facts may already exist. The loader preserves existing rows on conflict.

```sql
SELECT 'course_setup' AS fact, count(*) FROM analytics.course_scorecard
WHERE observation_id IN (SELECT observation_id FROM intake.observation WHERE request_key='verified2026:course_setup')
UNION ALL
SELECT 'rounds', count(*) FROM statistic.results_scoring_round
WHERE event_id = (SELECT event_id FROM intake.event_id_mapping WHERE provider='pgatour' AND namespace='tournament' AND season_id='2026-PGA' AND external_id='R2026030')
UNION ALL
SELECT 'predictions', count(*) FROM performance.shot_predictability_display
WHERE model_version='putt-outcomes-2026-v1';
```

## Calibrated putt outcomes

The model uses the previous physical stroke's measured remaining distance, when the stroke sequence establishes it before the putt. Logistic regression uses cubic features of log-transformed distance. A temperature is fitted on June events. Events starting in July or later are held out, including the replay event. Outcome labels are holed, missed within three feet, and missed beyond three feet. This is a retrospective distance-only baseline for putts, with no inferred club, weather, wellness, strokes gained, or target zone.

See [fit and holdout metrics](putt-outcomes-2026-v1.json) for sample counts, coefficients, temperature, log loss, Brier score and classwise calibration error. The loader only emits predictions after the holdout gate passes. The replay writes versioned outputs through `performance.shot_performance_predictability_output`. Use the [shot display export instructions](../Schema/README.md#shot-model-display) to open those rows in the browser.

## April 2021 Masters provider stats

[Migration 007](../Schema/007_reviewed_stat_mappings.sql) maps the six PGA TOUR strokes-gained IDs to their published per-round average definitions. It separately maps 11 Data Golf archive fields to player-round definitions. The two provider series retain their original grain and provenance. See the [PGA TOUR SG: Total definition](https://www.pgatour.com/stats/detail/02675) and [Data Golf field notes](https://datagolf.com/raw-data-notes).

Run from the repository root against a database with the schema and PGA TOUR player registry already installed.

```bash
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f Database/Schema/007_reviewed_stat_mappings.sql
python Database/Import/prepare_masters_stats.py > /tmp/golfdb-masters-stats.sql
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f /tmp/golfdb-masters-stats.sql
```

The generator reuses the verified Masters roster and reconciles every round score against the historical results. The load resolves PGATourID to canonical player UUIDs, preserves archive checksums, and stages unmapped or conflicting identities for review. It leaves blank metrics null by omitting those facts. The three percentage fields are converted from fractions to the 0–100 scale. Existing conflicting round scores or venue IDs abort the transaction.

Use `provider_stat_publication` in [catalog.sql](../Queries/catalog.sql) with provider `datagolf`, an archive field such as `sg_total`, season `2021-PGA`, the Masters event UUID, a round, and the observation ID printed by the load. PGA TOUR averages require a verified native publication. Repository fixtures are for tests and must stay out of the observations table. Unreviewed catalog IDs remain discoverable without a canonical mapping.
