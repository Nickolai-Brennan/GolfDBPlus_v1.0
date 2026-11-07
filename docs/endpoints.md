# Endpoint catalog

Verified on 2026-09-23. GraphQL query text is available in the linked file for
every operation; use the entire document, not only the operation name.

## Configuration

| Method | Route | Returns |
|---|---|---|
| `GET` | `https://orchestrator-config.pgatour.com/web-config` | Default tournament/leaderboard IDs by tour, current season numbers, and frontend configuration |

The shortest reliable discovery chain is:

```text
web-config -> defaultTournaments.R[0].leaderboardId -> leaderboard query
```

## REST

Base URL: `https://data-api.pgatour.com`

| Method | Path | Description |
|---|---|---|
| `GET` | `/player/list/{tour}` | Full player directory |
| `GET` | `/schedule/{tour}/{year}` | Season schedule |
| `GET` | `/player/profiles/{playerId}` | Profile overview |
| `GET` | `/player/profiles/{playerId}/career` | Career achievements and totals |
| `GET` | `/player/profiles/{playerId}/results` | All available tournament results |
| `GET` | `/player/profiles/{playerId}/results?season={year}` | Results for one season |
| `GET` | `/player/profiles/{playerId}/stats` | Full player stat profile |
| `GET` | `/player/profiles/{playerId}/bio` | Biography and amateur highlights |
| `GET` | `/odds/interactivity` | Odds widget configuration |
| `GET` | `/odds/tournament/{tournamentId}` | Betting-market catalog |
| `GET` | `/odds/tournament/{tournamentId}/player/{playerId}` | Markets for one player |
| `GET` | `/content/watch/speedRounds/{tour}` | Speed-round video index |

Public REST reads returned without user authentication during verification.

## GraphQL

Base URL: `https://orchestrator.pgatour.com/graphql`

### Tournament and live scoring

| Operation | Variables | Root field | Purpose |
|---|---|---|---|
| [`LeaderboardCompressedV3`](graphql/LeaderboardCompressedV3.graphql) | `leaderboardCompressedV3Id: ID!` | `leaderboardCompressedV3` | Full leaderboard, rounds, movement, cup ranks |
| [`CurrentLeadersCompressed`](graphql/CurrentLeadersCompressed.graphql) | `tournamentId: ID!` | `currentLeadersCompressed` | Compact top-leaders snapshot |
| [`LeaderboardHoleByHole`](graphql/LeaderboardHoleByHole.graphql) | `tournamentId: ID!`, `round: Int` | `leaderboardHoleByHole` | Hole-by-hole scores for the field |
| [`Field`](graphql/Field.graphql) | `fieldId: ID!`, `includeWithdrawn: Boolean`, `changesOnly: Boolean` | `field` | Entrants, alternates, withdrawals, OWGR |
| [`FieldStats`](graphql/FieldStats.graphql) | `tournamentId: ID!`, `fieldStatType: FieldStatType!` | `fieldStats` | Current-form or course-fit field data |
| [`TeeTimesCompressedV2`](graphql/TeeTimesCompressedV2.graphql) | `teeTimesCompressedV2Id: ID!` | `teeTimesCompressedV2` | Tee groups and start tees |
| [`ScorecardCompressedV3`](graphql/ScorecardCompressedV3.graphql) | `tournamentId: ID!`, `playerId: ID!` | `scorecardCompressedV3` | Player hole-by-hole scorecard |
| [`shotDetailsV4Compressed`](graphql/shotDetailsV4Compressed.graphql) | `tournamentId: ID!`, `playerId: ID!`, `round: Int!`, `includeRadar: Boolean` | `shotDetailsV4Compressed` | Shot play-by-play, coordinates, distances, radar |
| [`ScorecardStatsComparisonCategories`](graphql/ScorecardStatsComparisonCategories.graphql) | `tournamentId: String!`, `playerIds: [String!]!`, `category: PlayerComparisonCategory!` | `scorecardStatsComparison` | Head-to-head player comparison |
| [`Coverage`](graphql/Coverage.graphql) | `tournamentId: ID!` | `coverage` | TV and streaming windows |
| [`Weather`](graphql/Weather.graphql) | `tournamentId: ID!` | `weather` | Hourly/daily tournament forecast |
| [`CourseStats`](graphql/CourseStats.graphql) | `tournamentId: ID!` | `courseStats` | Per-hole course scoring |
| [`TournamentOverview`](graphql/TournamentOverview.graphql) | `tournamentId: ID!` | `tournamentOverview` | Overview tiles and champions |
| [`TournamentPastResults`](graphql/TournamentPastResults.graphql) | `tournamentPastResultsId: ID!`, `year: Int` | `tournamentPastResults` | Historical event leaderboard |
| [`Tournaments`](graphql/Tournaments.graphql) | `ids: [ID!]` | `tournaments` | Tournament metadata for one or more IDs |

### Statistics and standings

| Operation | Variables | Root field | Purpose |
|---|---|---|---|
| [`StatOverview`](graphql/StatOverview.graphql) | `tourCode: TourCode!`, `year: Int` | `statOverview` | Discover all categories and stat IDs |
| [`StatDetails`](graphql/StatDetails.graphql) | `tourCode: TourCode!`, `statId: String!`, `year: Int`, `eventQuery: StatDetailEventQuery` | `statDetails` | Ranking table for one stat |
| [`TourCupSplit`](graphql/TourCupSplit.graphql) | `tourCode: TourCode!`, `id: String`, `year: Int`, `eventQuery: StatDetailEventQuery` | `tourCupSplit` | FedExCup/season standings |
| [`SignatureStandings`](graphql/SignatureStandings.graphql) | `tourCode: TourCode!` | `signatureStandings` | Signature Event/Aon standings |
| [`PriorityRankings`](graphql/PriorityRankings.graphql) | `tourCode: TourCode!`, `year: Int` | `priorityRankings` | Exemption and priority categories |
| [`CourseStatsOverview`](graphql/CourseStatsOverview.graphql) | `tourCode: TourCode!`, `year: Int` | `courseStatsOverview` | Season course-stat hub |

Known `eventQuery` value: `LAST_5`; `null` requests the normal season view.

Known `fieldStatType` values: `CURRENT_FORM`, `COURSE_FIT`.

Known comparison categories vary by event; `SCORING` is a useful default.

### Odds

| Operation | Variables | Root field | Purpose |
|---|---|---|---|
| [`oddsToWinCompressed`](graphql/oddsToWinCompressed.graphql) | `tournamentId: ID!` | `oddsToWinCompressed` | Tournament winner odds |

The REST routes above expose the broader market catalog and per-player market
views. Odds can be empty when an event is not actively offered.

### News, video, and CMS content

| Operation | Variables | Root field | Purpose |
|---|---|---|---|
| [`NewsArticles`](graphql/NewsArticles.graphql) | `tour`, `franchises`, `playerIds`, `limit`, `offset`, `tags`, `sectionName` | `newsArticles` | Filtered/paginated articles |
| [`NewsFranchises`](graphql/NewsFranchises.graphql) | `tourCode`, `allFranchises` | `newsFranchises` | Available news filters |
| [`Videos`](graphql/Videos.graphql) | tournament/player/tour/season/filter/pagination variables | `videos` | Video and highlight catalog |
| [`TourcastVideos`](graphql/TourcastVideos.graphql) | `tournamentId: ID!`, `playerId: ID!`, `round: Int!`, optional `hole`, `shot` | `tourcastVideos` | Shot-specific clips |
| [`GenericContentCompressed`](graphql/GenericContentCompressed.graphql) | `path: String!` | `genericContentCompressed` | CMS content fragment by site path |

### Player status

| Operation | Variables | Root field | Purpose |
|---|---|---|---|
| [`getPlayerTournamentStatus`](graphql/getPlayerTournamentStatus.graphql) | `playerId: ID!` | `playerTournamentStatus` | Current-event score/status for a player |

## Common response shapes

### Decompressed leaderboard

Top-level keys include tournament format/status metadata and `players`. Each
player item contains:

- `player`: ID, display/short names, country, flag, amateur status
- `scoringData`: position, total, current score, thru, current round, tee time,
  course/group IDs, movement, total strokes, projected ranks, state, and rounds

### Shot details

Shot records can include round/hole/shot numbers, par, lie, sequence text,
stroke status, start/end coordinates, measured distance, remaining distance,
and radar measurements. Availability differs by tournament and hole.

### Stat details

`statDetails` includes title, description, headers, tour average, season/event
selectors, and ranked `rows`. A row contains player ID/name/country/rank and a
list of named stat values.

### REST schedule

The response contains tour/season metadata and `tournaments`. Event objects
include tournament ID, name, date display fields, status, purse, champion,
course/location, points, and event-site URL.

## Additional operations (verified 2026-09-24)

| Operation | Root | Variables | Compressed |
|---|---|---|---|
| ScorecardStatsV3Compressed | scorecardStatsV3Compressed | scorecardStatsV3CompressedId: ID!, playerId: ID! | Yes |
| CourseStatsDetails | courseStatsDetails | tourCode: TourCode!, queryType: CourseStatsId!, round: ToughestRound, year: Int | No |
| AllTimeRecordCategories | allTimeRecordCategories | tourCode: TourCode! | No |
| AllTimeRecordStat | allTimeRecordStat | tourCode: TourCode!, recordId: String! | No |

Course query types: TOUGHEST_COURSE and TOUGHEST_HOLES.
Record IDs are a separate catalogue, not season-stat IDs.
