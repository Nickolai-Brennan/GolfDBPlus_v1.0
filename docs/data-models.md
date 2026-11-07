# Return schemas

The normalized `pga_*` interface returns pandas DataFrames with stable,
snake-case columns. The raw `PgaApi` interface preserves upstream dictionaries.

## Leaderboard

One row per player. Verified shape for `R2026030`: 145 rows × 29 columns.

| Group | Columns |
|---|---|
| Identity | `player_id`, `first_name`, `last_name`, `display_name`, `short_name`, `country`, `country_flag`, `amateur` |
| Scoring | `position`, `total`, `total_sort`, `thru`, `score`, `score_sort`, `current_round`, `total_strokes` |
| Status | `player_state`, `tee_time`, `course_id`, `group_number`, `back_nine`, `official` |
| Movement | `movement_direction`, `movement_amount`, `projected` |
| Rounds | `round_1`, `round_2`, `round_3`, `round_4` |

Metadata such as format and tournament status is stored in `DataFrame.attrs`.

## Schedule

One row per tournament:

`tournament_id`, `tournament_name`, `year`, `month`, `display_date`, `status`,
`purse`, `fedex_cup_points`, `champion`, `champion_earnings`, `course_name`,
`city`, `state`, `country`, `tournament_site_url`.

## Player directory

One row per player:

`player_id`, `tour_code`, `is_primary`, `is_active`, `first_name`, `last_name`,
`display_name`, `short_name`, `country`, `country_flag`, `age`, `primary_tour`.

## Scorecard

One row per hole per round:

`round_number`, `hole_number`, `par`, `score`, `status`, `yardage`,
`round_score`, `sequence_number`, `course_name`, `round_total`,
`round_score_to_par`.

## Shot details

One row per recorded stroke. Core fields include `hole_number`, `par`,
`yardage`, `hole_status`, `hole_score`, `stroke_number`, `play_by_play`,
`distance`, `distance_remaining`, `stroke_type`, location names/codes, and
`final_stroke`.

Coordinate columns include both left-to-right and bottom-to-top start/end
coordinates, plus TOURCAST X/Y/Z measurements when available. Availability
varies by event and shot.

## Statistic rankings

Every ranking includes `stat_id`, `year`, rank/player identity fields, followed
by dynamic value columns derived from the API's `statHeaders`. For example,
Strokes Gained: Total currently includes `avg`, `total_sg_t`, `total_sg_t2_g`,
`total_sg_p`, and `measured_rounds`.

Descriptive metadata is stored in `DataFrame.attrs`, including `stat_title`,
`stat_description`, `tour_avg`, `year`, and `display_season`.

## Empty results

Live-only endpoints may return an empty DataFrame outside their active window.
Typical examples are odds, coverage, videos, and current tournament status.
An empty successful response is distinct from `PgaTourError`.
