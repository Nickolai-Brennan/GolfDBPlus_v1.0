# GolfDB+ source files

These 2026 Parquet snapshots are inputs for inspection and staged intake. The counts below describe the checked-in files. Event counts measure distinct source tournament IDs and do not certify full-season coverage.

| Snapshot | Rows | Events | Candidate row key within the season |
| --- | ---: | ---: | --- |
| [Course setup](course_setup_2026.parquet) | 3,276 | 43 | Tournament, round, course, hole |
| [Shots](shots_2026.parquet) | 1,044,397 | 41 | Tournament, player, round, course, hole, stroke |
| [Tee times](tee_times_2026.parquet) | 15,744 | 43 | Tournament, player, round, course |

- **Course setup** supplies par, yardage and pin coordinates. Confirm the coordinate frame before mapping pins.
- **Shots** supplies stroke results, coordinates and launch or flight measurements where available. The candidate key has 8,338 rows beyond the first row per key. Retain the source rows and inspect collisions before assigning canonical shot IDs.
- **Tee times** supplies player groups, starting tees and tee times. The Parquet timestamp stores UTC and the file also carries a separate timezone field.
- Course setup and tee times include `R2026014` and `R2026100`, which have no shot rows in this snapshot. Use coverage-aware joins to retain those events.

Keep `tournament_id`, `course_id` and `player_id` as text during staging. Resolve them through provider ID mappings before loading canonical tables. The files are available for offline inspection. Database migrations do not load them automatically.

From the repository root, verify the snapshot bytes with:

```bash
cd Data/Source-Files
sha256sum --check SHA256SUMS
```

See the [incoming data catalog](../../Database/Data-Catalog/README.md#source-routing) for routing and the [migration guide](../../Database/Schema/README.md#ingestion-transaction) for the staging and promotion process.
