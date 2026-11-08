# Live validation report

Verified on 2026-09-23 against completed event `R2026030` and player `59095`.
An `ok` with zero rows means the route responded normally but had no data in
that event state (most commonly completed-event odds, coverage, or video).

| Operation | Status | Result | Seconds |
|---|---:|---|---:|
| `pga_current_tournament` | ok | R2026500 | 0.435 |
| `pga_leaderboard` | ok | 145 rows, 29 columns | 0.424 |
| `pga_current_leaders` | ok | 15 rows, 13 columns | 0.266 |
| `pga_leaderboard_holes` | ok | 1487 rows, 14 columns | 2.046 |
| `pga_field` | ok | 160 rows, 14 columns | 0.700 |
| `pga_field_stats` | ok | 160 rows, 12 columns | 1.707 |
| `pga_tee_times` | ok | 445 rows, 12 columns | 0.586 |
| `pga_scorecard` | ok | 72 rows, 11 columns | 0.427 |
| `pga_shot_details` | ok | 62 rows, 35 columns | 0.619 |
| `pga_odds` | ok | 0 rows, 0 columns | 0.250 |
| `pga_odds_markets` | ok | 0 rows, 0 columns | 0.214 |
| `pga_player_odds` | ok | 0 rows, 0 columns | 0.184 |
| `pga_coverage` | ok | 0 rows, 0 columns | 0.224 |
| `pga_weather` | ok | 19 rows, 14 columns | 0.385 |
| `pga_course_stats` | ok | 105 rows, 19 columns | 0.310 |
| `pga_stats` | ok | 157 rows, 14 columns | 0.480 |
| `pga_fedex_cup` | ok | 219 rows, 14 columns | 0.821 |
| `pga_signature_standings` | ok | 20 rows, 11 columns | 0.361 |
| `pga_priority_rankings` | ok | 407 rows, 4 columns | 0.404 |
| `pga_scorecard_comparison` | ok | 6 rows, 2 columns | 0.791 |
| `pga_course_stats_overview` | ok | 12 rows, 5 columns | 0.555 |
| `pga_players` | ok | 2745 rows, 12 columns | 0.147 |
| `pga_tournaments` | ok | 1 rows, 24 columns | 0.406 |
| `pga_schedule` | ok | 49 rows, 15 columns | 0.075 |
| `pga_tournament_overview` | ok | dict: overview, defending_champion, past_champions, tickets_url, tourcast_url, share_url, event_guide_url | 0.493 |
| `pga_tournament_past_results` | ok | 144 rows, 21 columns | 0.588 |
| `pga_player_profile` | ok | dict: player_id, first_name, last_name, country, country_code, born, age, birthplace | 0.488 |
| `pga_player_career` | ok | 33 rows, 6 columns | 0.187 |
| `pga_player_results` | ok | 23 rows, 16 columns | 0.649 |
| `pga_player_stats` | ok | 131 rows, 11 columns | 0.500 |
| `pga_player_bio` | ok | dict: text, amateur_highlights, widgets | 0.184 |
| `pga_player_tournament_status` | ok | 0 rows, 0 columns | 0.414 |
| `pga_news` | ok | 5 rows, 16 columns | 2.124 |
| `pga_news_franchises` | ok | 7 rows, 2 columns | 0.429 |
| `pga_videos` | ok | 0 rows, 0 columns | 0.383 |
| `pga_tourcast_videos` | ok | 0 rows, 0 columns | 0.387 |
| `pga_odds_interactivity` | ok | dict: interactive, country, region | 0.332 |
| `pga_speed_rounds` | ok | dict: country, title, featureEnabled, speedRoundsEnabled, speedRoundsDisabledText, defaultTournament, defaultSeason, seasons | 0.325 |

## Observed totals

- Full player directory: 2,745 rows
- Completed tournament leaderboard: 145 rows
- Whole-field hole scoring: 1,487 rows
- Tee-time assignments: 445 rows
- One player's scorecard: 72 hole rows
- One player's final-round shots: 62 rows
- PGA TOUR priority rankings: 407 rows
- Player profile stats: 131 rows
