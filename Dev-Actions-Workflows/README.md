# Actions and Workflows

## Workflow A — PGA Event Document Collector
1. Select tour, season and event from GolfDB+ registry.
2. Fetch authorized official media event page (example: https://pgatourmedia.pgatourhq.com/tours/2026/pgatour/worldwidetechnologychampionship).
3. Discover file links, display titles, categories, round numbers and source URLs; deduplicate by normalized URL.
4. Download only accessible and permitted attachments with timeout, size limit, content validation, retry/backoff, SHA-256 and an explicit manifest. Use `--download` only after reviewing permissions.
5. Store original bytes under `Assets/Events/<event-slug>/Documents/<source>/<category>/` in a private working directory or object store, not a public commit.
6. Extract permitted transcript article links and referenced URLs into `script_markdown.md` under the same event folder. Keep source URL and date for each link.
7. Record provenance in `event_documents`. On restricted/JavaScript-only endpoints, record a blocked status and use an approved browser/API integration; never bypass access controls.
8. Parse PDF, CSV, HTML and XLSX into staging tables, validate then publish to query and analytics layers.

**ShotLink Reports:** Browser-assisted adapter is still needed to select season then event, inspect document list, and download authorized reports. Dynamic selector was not exposed as static HTML; do not claim a functioning bulk download until verified.

## Workflow B — Golf Content Intelligence
1. Expand search terms from canonical player aliases, event names and course names.
2. Use approved search providers, official news/RSS feeds, editorial sources and transcript metadata.
3. Collect title, source ID, URL, published date, retrieved date, content type and text only when permitted.
4. Normalize canonical URL, hash content, deduplicate, and parse citations/source claims.
5. Link mentions to players/events/courses using aliases + disambiguation; require review for ambiguous results.
6. Tag skill, recent form, historical results, course similarity, weather, injuries, setup changes, performance and playing style as hypotheses/evidence, not ground truth.
7. Index PostgreSQL full-text; add vector retrieval only after quality evaluation.
8. Link extracted features to source documents, capture observation/publication time, confidence and parser version.
9. For historical model training, only include documents published before each prediction cutoff (avoid temporal leakage).
10. Review licensing, sources, factual errors, bias, and model calibration.

### Operations
Manual dry-run first. Scheduled jobs are proposed, not enabled. Store secrets in environment variables or secrets manager. Idempotent upserts; log failures; no automatic publication of copyrighted source files.

### Acceptance checks
- Identical URL imported twice creates one manifest document entry.
- Missing files and blocked endpoints are reported, not silently treated as success.
- Every asset maps to event ID, source URL and checksum.
- Every content match has entity ID, matched string and confidence/review state.
- Feature calculations can reproduce the exact as-of evidence set.
