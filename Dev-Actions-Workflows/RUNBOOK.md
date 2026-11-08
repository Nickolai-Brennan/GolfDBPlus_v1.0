# Operator Runbook

Run with Python 3.11+; standard library only.

## Event discovery (does not download PDFs by default)
```bash
python Dev-Actions-Workflows/Workflows/event_collector.py \
  --url https://pgatourmedia.pgatourhq.com/tours/2026/pgatour/worldwidetechnologychampionship \
  --transcript-url https://tee-scripts.com/pgatour/wwtchampionship-com/ \
  --out Assets/Events/2026-PGA/world-wide-technology-championship
```
Read output manifest before opting into `--download`; use that flag only for content that may legally be retrieved and retained. The script parses HTML links, so JavaScript-created links and some non-file download endpoints will be missed. It cannot perform authenticated ShotLink Reports selection. Source terms and download permissions must be assessed separately.

## Search content staging (local/offline)
```bash
python Dev-Actions-Workflows/content_index.py \
  --input Dev-Actions-Workflows/examples/sample_content.jsonl \
  --aliases Dev-Actions-Workflows/examples/aliases.json \
  --out data/staging
```
These sample aliases are **not real IDs**; replace with verified records from GolfDB+. Export CSVs are staging files, not direct inserts into SQL tables. An ingestion step must resolve entity UUIDs, enforce constraints and record editorial review. This program does not crawl the web; upstream approved providers are required to supply JSONL.

## Database setup
```bash
psql "$DATABASE_URL" -f Database/Schema/install.psql
```
No DB migration has been executed by this commit. Add automated tests and a production backend connection before accepting imports.

For PGA TOUR statistics and scoring intake, see the [incoming data contract](../Database/Data-Catalog/README.md).
