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

Run the same installer for a database already on the UUID foundation. It adds tables and seeds mappings from the legacy columns. Future writes use the mapping tables. Review any provider IDs assigned independently in older pipelines before import. Installer roles need schema creation, table alteration and extension permissions where applicable.

The original bigint Shot Tracker design is a separate target. Its historical design notes are [here](../Data-Catalog/SHOT-TRACKER-LEGACY.md). `001_ingest.sql`, `002_tours_season.sql`, `003_reference_mapping_ids`, `004_admin_stats.sql`, `005_admin_dashboard.sql`, `core.sql` and `example.sql` are historical standalone scripts or design fragments outside the canonical install. The raw reference dictionary is research material containing prose and examples.

## Ingestion transaction

1. Archive original bytes privately and calculate SHA-256. Register the retrieval with the operation, stable request key and observation timestamp.
2. Stage normalized candidates with stable record keys. Reuse the same observation timestamp on retry. A distinct retrieval keeps a distinct observation even if bytes match.
3. Resolve source identifiers before promotion. Create reviewed canonical entities and first mappings transactionally. Roll back on mapping conflicts. For pending work, lock the staged record with `SELECT ... FOR UPDATE` before applying normalized writes.
4. Preserve and quarantine unresolved IDs, unknown units and invalid setup rows. Treat conflicting retry inputs as errors when a prepared statement returns zero rows. A quarantined row can be put back in the pending queue after review in an explicit transaction.
5. Write accepted facts and mark records accepted in the same transaction. Use complete current-row inputs, because these upserts replace the current row when evidence is newer. For immutable facts, an identical retry retains the original. Submit corrections under a new observation or model run.
6. Promote complete event publications together. Use their exact observation IDs for reads. Keep a partially resolved batch staged until the gaps are reconciled.

See the [catalog and ERD](../Data-Catalog/README.md) for the full inventory and source-to-table mapping.
