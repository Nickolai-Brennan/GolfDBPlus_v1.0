# GolfDB+ Data Catalog

## Architecture
Three product sections: **Data Entry**, **Stats & Metrics**, **Models**. Three master data categories: **Players**, **Events**, **Courses**.

### Data Entry modules
- Entity Registry: internal GolfDB+ ID, source mappings, aliases, merge history and review flags.
- Collection: manual form, bulk CSV/JSON, official-attachment discovery, scheduled collectors.
- Data Quality: schema validation, provenance, duplicates, missing IDs, integrity and quarantine.
- Query Studio: SQL, full-text lookup, saved searches and exports.
- Asset Browser: original documents, images, transcripts and derived text.

### Stats & Metrics
Time-stamped, versioned shot, round, event, player, course and hole measurements; source-specific units; derived metrics and rankings. Never overwrite raw values with estimates.

### Models
Feature store, time-aware training datasets, run metadata, predictions, calibration and backtests. Link model features to exact document and metric provenance; prohibit future information from leaking into historical backtests.

## Data dictionary
| Entity | Stable primary key | External IDs | Notes |
|---|---|---|---|
| players_tracking | playerid UUID | datagolfID, pgatourID, espnID, cbssportsID, rickrungoodID | ISO 3166-1 alpha-3 nationality; current location is mutable |
| courses | coursesID UUID | pgatour_coursesID, datagolf_coursesID | country flag is derived from country code |
| events | eventsID UUID | pgatour_eventsID, datagolf_eventsID | linked to tourID and seasonID |
| tours | tourID TEXT | mapping table for third-party tour codes | PGA, DP, LIV, SEN, ASIA |
| seasons | seasonID TEXT | per-source season IDs optional | Format YYYY-TOUR, e.g. 2026-PGA |
| event_documents | document_id UUID | source URL, hash | download state, license, publication date |
| content_items | content_id UUID | canonical URL, hash | full text, entity associations, publish date |

## Data lineage contract
Each raw file must register source_system, original_url, discovered_at, retrieved_at, content_type, sha256, bytes, license/access status, stored_path, parser_version, and extraction status. Store original and parsed layers separately. A URL alone is not evidence of permission to redistribute.

## Collection policy
Respect official terms, robots directives where applicable, account access, document copyright, API rate limits and source response codes. No bypass of login, paywall or download restrictions. Do not commit proprietary attachments or credentials to public GitHub. For production, put files in private object storage and keep only manifest files and approved samples in git.
