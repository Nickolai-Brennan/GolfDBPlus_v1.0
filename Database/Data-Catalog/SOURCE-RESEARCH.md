# Source and coverage notes

| Evidence | Design consequence |
| --- | --- |
| The supplied PGA TOUR GraphQL documents describe the selected fields and variables. A compressed payload is opaque until decoded. | Store request context and original bytes, then decode and inspect fixture shapes. Retain provider provenance when flattening. |
| PGA TOUR stat catalog examples include `02675` for SG: Total and `02567` for SG: Off-the-Tee. | Use text IDs. Map source stat codes to reviewed internal definitions. Season-stat and record IDs are separate namespaces. |
| The historical PGA results file has season, event dates, venue text, player names, finishing status, round scores, earnings and points. | Treat it as event-result evidence. Quarantine ambiguous identity matches and keep source finish text. |
| The Data Golf round file supplies `dg_id`, `course_num`, event ID, season, start hole, tee time and round statistics. | Resolve identities by provider and season. Keep round metrics at round grain. |
| The ASA archive is labeled tournament level. | Keep raw provenance and establish its measure definitions before joining against Data Golf or PGA observations. |
| Earlier Tourcast access from the development environment returned HTTP 403. | Validate ingestion offline. A credentialed live collection run remains an independent release gate. |

Repository references are the [API endpoint manifest](../../PGA-Tour-Data-API/endpoint_manifest.json), [stat catalog](../../PGA-Tour-Data-API/data/stat_ids.csv), [existing API validation report](../../PGA-Tour-Data-API/VALIDATION.md) and [reference dictionary](../Reference_Dictionary.sql).
