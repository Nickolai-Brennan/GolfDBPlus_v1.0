# API Reference

## Live Tournament Data

::: pga_tour_api.pga_current_tournament

::: pga_tour_api.pga_leaderboard

::: pga_tour_api.pga_field

::: pga_tour_api.pga_field_stats

::: pga_tour_api.pga_leaderboard_holes

::: pga_tour_api.pga_current_leaders

::: pga_tour_api.pga_tee_times

::: pga_tour_api.pga_scorecard

::: pga_tour_api.pga_shot_details

::: pga_tour_api.pga_odds

::: pga_tour_api.pga_odds_markets

::: pga_tour_api.pga_player_odds

::: pga_tour_api.pga_historical_odds

::: pga_tour_api.pga_historical_tournaments_odds

::: pga_tour_api.pga_coverage

::: pga_tour_api.pga_weather

::: pga_tour_api.pga_course_stats

## Statistics & Standings

::: pga_tour_api.pga_stats

::: pga_tour_api.pga_fedex_cup

::: pga_tour_api.pga_signature_standings

::: pga_tour_api.pga_priority_rankings

::: pga_tour_api.pga_scorecard_comparison

::: pga_tour_api.pga_course_stats_overview

## Players & Tournaments

::: pga_tour_api.pga_players

::: pga_tour_api.pga_tournaments

::: pga_tour_api.pga_schedule

::: pga_tour_api.pga_tournament_overview

::: pga_tour_api.pga_tournament_past_results

## Player Profiles

::: pga_tour_api.pga_player_profile

::: pga_tour_api.pga_player_career

::: pga_tour_api.pga_player_results

::: pga_tour_api.pga_player_stats

::: pga_tour_api.pga_player_bio

::: pga_tour_api.pga_player_tournament_status

## Content

::: pga_tour_api.pga_news

::: pga_tour_api.pga_news_franchises

::: pga_tour_api.pga_videos

::: pga_tour_api.pga_tourcast_videos

::: pga_tour_api.pga_content

::: pga_tour_api.pga_odds_interactivity

::: pga_tour_api.pga_speed_rounds

## Errors

::: pga_tour_api.PgaTourError

## Records and detailed performance

Added on 2026-09-24: four functions and four GraphQL operations. These are
unofficial upstream data, not independently validated records.

```python
import pga_tour_api as pga

stats = pga.pga_scorecard_stats("R2026030", "59095", round="-1")
courses = pga.pga_course_stats_details(year=2026)
holes = pga.pga_course_stats_details("TOUGHEST_HOLES", year=2026, round="ONE")
catalog = pga.pga_record_catalog()
records = pga.pga_all_time_records("2-1-11")
```

Scorecard sections are performance, scoring and strokesGained; the same stat
can appear in more than one section. Round "-1" is the aggregate. Course round
selectors are ALL, ONE, TWO, THREE and FOUR. Availability varies by tour and season.
Display values remain strings; identifiers retain leading zeroes. Table metadata
and original headers are available through `DataFrame.attrs`.
Course duplicate headers are disambiguated (par/par_1 and dbl_bogey/dbl_bogey_1).
Missing data produces an empty table; mismatched headers raise PgaTourError.

::: pga_tour_api.pga_scorecard_stats

::: pga_tour_api.pga_course_stats_details

::: pga_tour_api.pga_record_catalog

::: pga_tour_api.pga_all_time_records

### PGA TOUR University

`pga_university_rankings(year=None, week=None)` returns player rankings, schools,
movement, averages and tournament history. `pga_university_total_points(season=None,
week=None)` returns the combined points table and preserves source headers and
navigation metadata in `DataFrame.attrs`.

::: pga_tour_api.pga_university_rankings

::: pga_tour_api.pga_university_total_points

### DP World Tour eligibility

`pga_dp_world_tour_eligibility(year=None)` wraps the PGA site's existing
`TourCupSplit` operation with ranking ID `2700` and returns Race to Dubai
eligibility standings. The source metadata is retained in `DataFrame.attrs`.

::: pga_tour_api.pga_dp_world_tour_eligibility

### Playoff data

`pga_playoff_scorecard(tournament_id)` and `pga_playoff_shot_details(tournament_id)`
wrap the PGA TOUR playoff-specific operations. A completed event may legitimately
return an empty table when no playoff occurred; compressed shot payloads are decoded
while preserving the upstream message and ID in `DataFrame.attrs`.

::: pga_tour_api.pga_playoff_scorecard

::: pga_tour_api.pga_playoff_shot_details

### Team events

`pga_team_stroke_play_leaderboard(tournament_id)` returns team standings and
player membership for team-stroke events. `pga_cup_team_roster(tournament_id)`
returns cup teams, sections and player match results.

::: pga_tour_api.pga_team_stroke_play_leaderboard

::: pga_tour_api.pga_cup_team_roster

`pga_match_play_leaderboard(tournament_id)` flattens the compressed match-play
feed to one row per player per match. It preserves round, bracket/group,
match score, status, tee time, seeds and country fields, and includes an
`upcoming` flag for scheduled matches. For example, the 2023 WGC-Dell
Technologies Match Play is available as `R2023470`.

::: pga_tour_api.pga_match_play_leaderboard

### Editorial tables

`pga_power_rankings(path)` and `pga_expert_picks(path)` consume the content
fragment path embedded in a PGA TOUR article, not the public article URL. The
article page supplies paths such as `/content/dam/pga-tour/fragments/.../pr-table`.
Nested lineups remain lists so the original editorial selection is preserved.

::: pga_tour_api.pga_power_rankings

::: pga_tour_api.pga_expert_picks


### Season player comparisons

```python
comparison = pga.player_comparison(["59095", "34046"], year=2026, category="SCORING")
```

::: pga_tour_api.pga_player_comparison
