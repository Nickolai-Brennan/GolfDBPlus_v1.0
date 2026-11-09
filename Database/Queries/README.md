# GolfDB+ page queries

The [schema folders](../Schemas/README.md) organize the complete prepared query set. [catalog.sql](catalog.sql) expands the page-facing reads and uses parameters so the same statement can serve every metric or provider stat ID. It preserves PGA TOUR IDs as text, including leading zeroes.

## Run from the repository root

```bash
psql "$DATABASE_URL" -X -f Database/Schema/install.psql
psql "$DATABASE_URL" -X -f Database/Queries/load_provider_stat_catalog.psql
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f Database/Queries/catalog.sql \
  -c "EXECUTE stat_catalog_search('pgatour', 'Strokes Gained', '02675');"
```

## Pages and query contracts

| Page | Query families |
|---|---|
| Home and event directory | `event_directory`, `event_window`, `event_coverage` |
| Player database and profiles | `player_directory`, `player_provider_ids`, `player_profile`, `player_event_history`, `player_round_history` |
| Player rankings and World Map | `published_ranking`, `player_ranking_history`, `metric_leaderboard`. The player directory supports a nationality filter. |
| Player stats and Snapshot Explorer | `stat_catalog_search`, `metric_definition_search`, `metric_publication`, `provider_stat_publication`, `player_metric_series`, `player_par_splits` |
| Event details and past results | `event_metadata`, `event_venues`, `event_leaderboard`, `event_results`, `result_publications`, `statistic_event_scoring` |
| Field, tee times, Round Center and scorecard | `event_round_field`, `event_round_scores`, `event_round_ranking`, `event_scorecard`, `performance_round_totals`. The field query covers stored rounds. |
| Course directory, profile, traits and difficulty | `course_directory`, `course_profile`, `course_setup`, `course_scorecard`, `statistic_course_card`, `course_performance`, `course_difficulty`, `hole_metrics`, `event_hole_difficulty_ranking`, `course_hole_source_history` |
| Shot Lab, Shot Map and 3D Putt Lab inputs | `shot_map_points`, `shot_measurement_values`, `shot_measurement_summary`, `event_shot_measurement_ranking`. Respect the source coordinate frame and check source completeness before attempting a 3D reconstruction. |
| Models, player ratings, event projections | `player_outputs`, `event_projection_outputs`, `performance_shot_predictions`. Query exact model versions and run IDs where required. |
| Media and social views | `entity_content_search` for approved entity links. Social follower histories require dedicated source data. |
| Data entry, Query Studio and operations | `schema_columns`, `lookup_values`, `intake_coverage`, `quarantined_records`, and the existing registry and intake statements. |

Rookies, dedicated field membership, current market odds, prestige, similarity, forecast/weather, video availability, green meshes, and job status require ingested facts or model outputs before their pages can show results. An empty query response does not establish a zero-valued statistic.

## Sources and coverage

| Source files or operations | Query target |
|---|---|
| [Stat ID CSV](../../PGA-Tour-Data-API/data/stat_ids.csv), `StatOverview`, `StatDetails`, `ScorecardStatsComparisonCategories` | Discover all 467 provider IDs across nine categories. Map each ID to a reviewed metric definition before reading numeric values. Comparison categories are labels. |
| `PriorityRankings`, `SignatureStandings` | Store source positions and points by provider, series, scope and publication in `statistic.player_ranking_publication`. The catalog includes ranking IDs but does not seed ranking values. |
| `Tournaments`, `TournamentOverview`, `TournamentPastResults`, `LeaderboardCompressedV3`, `LeaderboardHoleByHole`, `TeeTimesCompressedV2`, `ScorecardCompressedV3`, `getPlayerTournamentStatus` | Season and edition details, observed leaderboard publications, rounds and hole scores. Preserve publication IDs and keep status feeds separate from finalized scores. |
| `CourseStats`, `CourseStatsOverview`, 2026 course setup and tee-time Parquet | Course setup, published course statistics, measured scoring difficulty, and round tee times. |
| `shotDetailsV4Compressed`, 2026 shot Parquet | Shot geometry and measured shot facts. The measurement view reads eight core codes plus verified radar measures in `performance.shot_source_measurement`. Additional radar facts require validated source values and units. |
| `NewsArticles`, `NewsFranchises`, `GenericContentCompressed`, `Videos`, `TourcastVideos` | Content and reviewed entity links. These GraphQL operations describe retrieval, while SQL reads saved records. |
| `oddsToWinCompressed` | Market data retrieval. Archive timestamps and market semantics before exposing quotes. |
| Historical PGA results TSV, Masters round TSV and ASA tournament CSV archive | Historical results, provider crosswalks, strokes gained and tournament-grain analysis. Use the [source routing and identity rules](../Data-Catalog/README.md#source-routing). Preserve ASA fantasy provider points as separate definitions and validate source ID namespaces. |

For values and computed ranks, select one season, scope, metric version and observation. Pass NULL for both event and round to select season-grain values. Pass NULL for only round to select event-grain values. Use explicit `asc` for lower-is-better metrics and `desc` for higher-is-better metrics. Published ranks retain the provider's tie policy. Computed ranks use competition ranking. Shot measurement summaries group by unit and count observations. Additional radar observations can include source revisions for a shot.
