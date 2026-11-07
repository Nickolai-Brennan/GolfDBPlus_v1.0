# Raw client

`PgaApi` is the lower-level, object-oriented interface. Its convenience methods
decode compressed responses but otherwise preserve upstream field names and
response structures. Use it when you need the original nested JSON rather than
normalized pandas DataFrames.

::: pga_tour_api.PgaApi

::: pga_tour_api.PgaApiError

## Detailed statistics and records

The raw client also exposes `scorecard_stats(tournament_id, player_id)`,
`course_stats_details(query_type="TOUGHEST_COURSE", year=None, tour="R", round="ALL")`,
`record_catalog(tour="R")`, and `all_time_records(record_id, tour="R")`.
These preserve upstream structures; scorecard statistics are automatically decompressed.

The raw client also exposes `player_comparison(player_ids, category="SCORING", year=None, tour="R", tournament_id=None)`, returning the PGA comparison table unchanged.

It also exposes `university_rankings(year=None, week=None)` and
`university_total_points(season=None, week=None)`.

`dp_world_tour_eligibility(year=None, tour="R")` returns the raw Race to Dubai
eligibility standings.

`power_rankings(path)` and `expert_picks(path)` return the raw editorial tables
for a content-fragment path embedded in a PGA TOUR article.

`historical_odds(tournament_id, player_id, market_id="WINNER")` and
`historical_tournaments_odds(tournament_id, market_id="WINNER")` preserve the
historical odds responses, including the upstream availability message.
