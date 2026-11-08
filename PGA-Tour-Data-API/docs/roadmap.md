# Expansion roadmap

Research date: **2026-09-25**. These additions were discovered by inspecting
public PGA TOUR pages and their shipped query documents, then making selected
live requests. The delivered items below are implemented in the package;
remaining rows are explicitly marked as upstream-dependent or unverified.

## Live-verified additions

| Priority | Addition | Evidence from this investigation | Proposed package support |
|---|---|---|---|
| Delivered | Player tournament performance statistics | `ScorecardStatsV3Compressed` returned and decoded player `59095`'s statistics for event `R2026030`, including strokes gained, ranks, and year-to-date comparisons. | A raw method and a normalized table of player statistics by round and category. |
| Delivered | Full course and hole rankings | `CourseStatsDetails` returned 41 courses for `TOUGHEST_COURSE` and 738 holes for `TOUGHEST_HOLES`, using tour `R`, year `2026`, and round `ALL`. Season selectors extended back to 2008. | Implemented as full ranking tables with season, round, and ranking-type filters. |
| Delivered | All-time records | `AllTimeRecordCategories` returned 282 distinct record IDs across 13 categories. `AllTimeRecordStat` returned 86 rows for record `2-1-11` (lowest 18-hole score). | Implemented as a searchable record catalogue and record-detail function. These IDs are distinct from the 467 season-stat IDs. |
| Delivered | Season-level player comparisons | `PlayerComparison` returned a comparison table for players `59095` and `34046`, tour `R`, year `2026`, category `SCORING`. | Player comparisons by year and category, beyond the existing tournament scorecard comparison. |
| Delivered | PGA TOUR University rankings | `UniversityRankings` returned 92 players for season `2027`, plus week/year selectors and player event results. | Implemented as ranking and event-result tables with year/week filters. |
| Delivered | PGA TOUR University total points | `UniversityTotalPoints` returned 24 players for season `2026`, with season/week navigation. | Implemented as a separate qualification-points table. |

These are snapshot results, not fixed dataset sizes. One successful request
does not establish coverage for every season, player, tour, or record ID.
In particular, the 282-record catalogue was enumerated, but all 282 record
detail calls were not individually tested.

## Additional live-verified tour data

- **DP World Tour eligibility rankings:** implemented via the verified
  `TourCupSplit` operation with ranking ID `2700`; the 2026 request returned 21
  official players.

## Scheduled live coverage

The repository includes `scripts/smoke_live.py` and a weekly GitHub Actions
workflow. It checks representative historical responses for playoff scorecards,
playoff shot details, team-stroke-play leaderboards, match-play leaderboards,
and cup-team rosters. These checks are deliberately separate from the offline
test suite because the browser-facing service can change or rate-limit requests.

## Query definitions found; usable data still to verify

| Area | Examples of discovered operations | Remaining work |
|---|---|---|
| Delivered / follow-up | `PlayoffScorecardV3`, `PlayoffShotDetailsCompressed` | Wrappers and populated/empty fixtures are implemented; a completed event with actual playoff strokes would provide stronger live validation. |
| Delivered | `TeamStrokePlayLeaderboardCompressed`, `CupTeamRoster`, `MatchPlayLeaderboardCompressed` | Team-stroke, cup-roster and match-play wrappers are implemented and live-verified. Match play was verified on `R2023470` (2023 WGC-Dell Technologies Match Play), including knockout and group rounds. |
| Implemented / upstream-dependent | `HistoricalOdds`, `HistoricalTournamentsOdds` | Raw and normalized wrappers preserve populated markets when available and return empty DataFrames with the upstream “Odds are unavailable” message when not. |
| Delivered | `GetPowerRankingsTable`, `GetExpertPicksTable` | Article content-fragment paths were verified with structured 15-row and five-row responses. |
| Unverified / excluded | `LeaderboardStats` | The default request for completed event `R2026030` returned type `PROBABILITY` with no players; it remains outside the normalized surface until a populated event is found. |

### Historical odds verification note

The service accepts `OddsMarketType` values `WINNER`, `GROUP_WINNER`,
`NATIONALITY`, `PLAYER_PROPS`, `FINISHES` and `MATCHUP`, and `HistoricalOddsId`
values `WINNER`, `TOP_RANKED_3`, `TOP_RANKED_5`, `TOP_RANKED_10` and
`TOP_RANKED_20`. The operation expects `tournamentId: String!` and
`marketId: OddsMarketType!`. Requests for 11 current-season/completed IDs
(including `R2025018`, `R2026030` and `R2026500`) across `WINNER`,
`GROUP_WINNER` and `FINISHES` all returned a structured `FANDUEL` response
with the explicit message “Odds are unavailable.” The client now exposes raw
and normalized wrappers, but does not invent rows when the upstream market is
empty; the DataFrame retains the provider and availability message in
`attrs`.

## Delivery checklist for implemented additions

For each addition:

- [x] Verify the complete request and relevant filters against live data.
- [x] Bundle the query document and any required fragments.
- [x] Add raw access and a normalized function where the response fits a table.
- [x] Preserve identifiers, season/round context, and response metadata.
- [x] Add representative fixtures and tests for populated and empty responses.
- [x] Document parameters, return columns, limitations, and a working example.
- [x] Update the endpoint manifest, changelog, and counts only after implementation.

## Sources

- [PGA TOUR statistics and records](https://www.pgatour.com/stats)
- [Toughest courses](https://www.pgatour.com/stats/course/toughest-course)
- [Toughest holes](https://www.pgatour.com/stats/course/toughest-holes)
- [PGA TOUR University](https://www.pgatour.com/university)
- [University total points](https://www.pgatour.com/university/total-points)
- [DP World Tour eligibility rankings](https://www.pgatour.com/dp-world-tour-eligibility-rankings)

The query definitions were observed in the site's public frontend bundle
`_app-1177e9b067f9f99b.js` (build `pgatour-prod-2.32.2`). Bundle names may change;
discover the scripts from the current page when repeating the investigation.
