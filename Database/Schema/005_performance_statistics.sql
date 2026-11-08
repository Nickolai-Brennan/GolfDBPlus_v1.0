BEGIN;
CREATE SCHEMA IF NOT EXISTS performance;
CREATE SCHEMA IF NOT EXISTS statistic;

-- Canonical player UUIDs remain the join keys. PGA TOUR IDs are text.
CREATE OR REPLACE VIEW statistic.player_registry AS
SELECT p.playerid AS player_id, m.external_id AS pgatour_id, p.player_fullname AS player_name,
       p.nationality_country, i.given_name, i.family_name, i.birth_date,
       i.college, i.headshot_url, i.observation_id
FROM public.players_tracking p
JOIN intake.player_id_mapping m ON m.player_id = p.playerid AND m.provider = 'pgatour'
JOIN analytics.player_info i ON i.player_id = p.playerid;

-- Keep alternate venues and publication revisions explicit.
CREATE OR REPLACE VIEW statistic.results_events_positioning AS
SELECT r.player_id, r.event_id, e."coursesID" AS course_id, p.player_fullname AS player_name,
       r.total_strokes AS event_score, r.score_to_par AS over_under,
       r.position, r.position_display, r.status, r.earnings_amount AS prize_earnings,
       r.earnings_currency, r.fedex_points, r.observation_id, e."seasonID" AS season_id
FROM analytics.event_results r
JOIN public.events e ON e."eventsID" = r.event_id
JOIN public.players_tracking p ON p.playerid = r.player_id;

CREATE OR REPLACE VIEW statistic.results_scoring_round AS
SELECT r.player_id, p.player_fullname AS player_name, r.event_id, r.course_id,
       e.starts_on, e.ends_on, r.round_number, r.tee_time, r.strokes AS score,
       r.score_to_par AS over_under, e."seasonID" AS season_id
FROM analytics.player_round r
JOIN public.events e ON e."eventsID" = r.event_id
JOIN public.players_tracking p ON p.playerid = r.player_id;

CREATE OR REPLACE VIEW statistic.results_scoring_event_basic AS
WITH rounds AS (
    SELECT player_id, event_id,
           max(score) FILTER (WHERE round_number = 1) AS round1_score,
           max(score) FILTER (WHERE round_number = 2) AS round2_score,
           max(score) FILTER (WHERE round_number = 3) AS round3_score,
           max(score) FILTER (WHERE round_number = 4) AS round4_score
    FROM statistic.results_scoring_round GROUP BY player_id, event_id
)
SELECT r.player_id, r.event_id, e.event_name, r.course_id, c.course_name,
       a.round1_score, a.round2_score, a.round3_score, a.round4_score,
       r.event_score AS total_score, r.over_under, e.starts_on, e.ends_on,
       r.observation_id, r.season_id
FROM statistic.results_events_positioning r
JOIN public.events e ON e."eventsID" = r.event_id
LEFT JOIN public.courses c ON c."coursesID" = r.course_id
LEFT JOIN rounds a USING (player_id, event_id);

ALTER TABLE analytics.course_scorecard ADD COLUMN IF NOT EXISTS handicap smallint
    CHECK (handicap BETWEEN 1 AND 18);

CREATE OR REPLACE VIEW statistic.course_scorecard AS
SELECT event_id, course_id, round_number, hole_number, yards AS hole_yards, par, handicap,
       CASE WHEN count(*) FILTER (WHERE hole_number <= 9) OVER setup = 9
            THEN sum(par) FILTER (WHERE hole_number <= 9) OVER setup END AS front9_par,
       CASE WHEN count(*) FILTER (WHERE hole_number > 9) OVER setup = 9
            THEN sum(par) FILTER (WHERE hole_number > 9) OVER setup END AS back9_par,
       CASE WHEN count(*) OVER setup = 18 THEN sum(par) OVER setup END AS total_par,
       CASE WHEN count(yards) OVER setup = 18 THEN sum(yards) OVER setup END AS yards_course
FROM analytics.course_scorecard
WINDOW setup AS (PARTITION BY event_id, course_id, round_number);

-- These metrics are supplied by reviewed scoring data, or derived from validated
-- shot sequences. NULL means coverage is unknown.
CREATE TABLE IF NOT EXISTS performance.player_hole_metrics (
    event_id uuid, player_id uuid, round_number smallint, hole_number smallint,
    observation_id bigint NOT NULL REFERENCES intake.observation,
    drive_distance_yards numeric CHECK (drive_distance_yards >= 0),
    fir boolean, gir boolean,
    gir_distance_to_hole_feet numeric CHECK (gir_distance_to_hole_feet >= 0),
    putts smallint CHECK (putts >= 0),
    PRIMARY KEY (event_id, player_id, round_number, hole_number),
    FOREIGN KEY (event_id, player_id, round_number, hole_number)
        REFERENCES analytics.player_hole_score
);

CREATE OR REPLACE VIEW performance.player_tracker_hole AS
SELECT h.player_id, h.event_id, h.course_id, h.round_number, h.hole_number,
       COALESCE(s.par, base.par) AS par, COALESCE(s.yards, base.yards) AS hole_yards,
       m.drive_distance_yards, m.fir, m.gir, m.gir_distance_to_hole_feet, m.putts,
       h.strokes AS hole_score
FROM analytics.player_hole_score h
LEFT JOIN performance.player_hole_metrics m USING (event_id, player_id, round_number, hole_number)
LEFT JOIN analytics.course_scorecard s USING (event_id, course_id, round_number, hole_number)
LEFT JOIN analytics.course_scorecard base
  ON (base.event_id, base.course_id, base.round_number, base.hole_number)
   = (h.event_id, h.course_id, 0, h.hole_number);

CREATE OR REPLACE VIEW performance.player_tracker_round AS
SELECT player_id, event_id, course_id, round_number,
       max(par) FILTER (WHERE hole_number = 1) AS hole1_par,
       max(hole_yards) FILTER (WHERE hole_number = 1) AS hole1_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 1) AS hole1_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 1) AS hole1_fir,
       bool_or(gir) FILTER (WHERE hole_number = 1) AS hole1_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 1) AS hole1_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 1) AS hole1_putts,
       max(hole_score) FILTER (WHERE hole_number = 1) AS hole1_score,
       max(par) FILTER (WHERE hole_number = 2) AS hole2_par,
       max(hole_yards) FILTER (WHERE hole_number = 2) AS hole2_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 2) AS hole2_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 2) AS hole2_fir,
       bool_or(gir) FILTER (WHERE hole_number = 2) AS hole2_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 2) AS hole2_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 2) AS hole2_putts,
       max(hole_score) FILTER (WHERE hole_number = 2) AS hole2_score,
       max(par) FILTER (WHERE hole_number = 3) AS hole3_par,
       max(hole_yards) FILTER (WHERE hole_number = 3) AS hole3_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 3) AS hole3_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 3) AS hole3_fir,
       bool_or(gir) FILTER (WHERE hole_number = 3) AS hole3_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 3) AS hole3_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 3) AS hole3_putts,
       max(hole_score) FILTER (WHERE hole_number = 3) AS hole3_score,
       max(par) FILTER (WHERE hole_number = 4) AS hole4_par,
       max(hole_yards) FILTER (WHERE hole_number = 4) AS hole4_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 4) AS hole4_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 4) AS hole4_fir,
       bool_or(gir) FILTER (WHERE hole_number = 4) AS hole4_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 4) AS hole4_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 4) AS hole4_putts,
       max(hole_score) FILTER (WHERE hole_number = 4) AS hole4_score,
       max(par) FILTER (WHERE hole_number = 5) AS hole5_par,
       max(hole_yards) FILTER (WHERE hole_number = 5) AS hole5_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 5) AS hole5_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 5) AS hole5_fir,
       bool_or(gir) FILTER (WHERE hole_number = 5) AS hole5_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 5) AS hole5_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 5) AS hole5_putts,
       max(hole_score) FILTER (WHERE hole_number = 5) AS hole5_score,
       max(par) FILTER (WHERE hole_number = 6) AS hole6_par,
       max(hole_yards) FILTER (WHERE hole_number = 6) AS hole6_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 6) AS hole6_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 6) AS hole6_fir,
       bool_or(gir) FILTER (WHERE hole_number = 6) AS hole6_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 6) AS hole6_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 6) AS hole6_putts,
       max(hole_score) FILTER (WHERE hole_number = 6) AS hole6_score,
       max(par) FILTER (WHERE hole_number = 7) AS hole7_par,
       max(hole_yards) FILTER (WHERE hole_number = 7) AS hole7_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 7) AS hole7_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 7) AS hole7_fir,
       bool_or(gir) FILTER (WHERE hole_number = 7) AS hole7_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 7) AS hole7_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 7) AS hole7_putts,
       max(hole_score) FILTER (WHERE hole_number = 7) AS hole7_score,
       max(par) FILTER (WHERE hole_number = 8) AS hole8_par,
       max(hole_yards) FILTER (WHERE hole_number = 8) AS hole8_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 8) AS hole8_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 8) AS hole8_fir,
       bool_or(gir) FILTER (WHERE hole_number = 8) AS hole8_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 8) AS hole8_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 8) AS hole8_putts,
       max(hole_score) FILTER (WHERE hole_number = 8) AS hole8_score,
       max(par) FILTER (WHERE hole_number = 9) AS hole9_par,
       max(hole_yards) FILTER (WHERE hole_number = 9) AS hole9_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 9) AS hole9_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 9) AS hole9_fir,
       bool_or(gir) FILTER (WHERE hole_number = 9) AS hole9_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 9) AS hole9_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 9) AS hole9_putts,
       max(hole_score) FILTER (WHERE hole_number = 9) AS hole9_score,
       CASE WHEN count(*) FILTER (WHERE hole_number <= 9) = 9
            THEN sum(hole_score) FILTER (WHERE hole_number <= 9) END AS front9_score,
       max(par) FILTER (WHERE hole_number = 10) AS hole10_par,
       max(hole_yards) FILTER (WHERE hole_number = 10) AS hole10_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 10) AS hole10_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 10) AS hole10_fir,
       bool_or(gir) FILTER (WHERE hole_number = 10) AS hole10_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 10) AS hole10_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 10) AS hole10_putts,
       max(hole_score) FILTER (WHERE hole_number = 10) AS hole10_score,
       max(par) FILTER (WHERE hole_number = 11) AS hole11_par,
       max(hole_yards) FILTER (WHERE hole_number = 11) AS hole11_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 11) AS hole11_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 11) AS hole11_fir,
       bool_or(gir) FILTER (WHERE hole_number = 11) AS hole11_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 11) AS hole11_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 11) AS hole11_putts,
       max(hole_score) FILTER (WHERE hole_number = 11) AS hole11_score,
       max(par) FILTER (WHERE hole_number = 12) AS hole12_par,
       max(hole_yards) FILTER (WHERE hole_number = 12) AS hole12_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 12) AS hole12_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 12) AS hole12_fir,
       bool_or(gir) FILTER (WHERE hole_number = 12) AS hole12_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 12) AS hole12_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 12) AS hole12_putts,
       max(hole_score) FILTER (WHERE hole_number = 12) AS hole12_score,
       max(par) FILTER (WHERE hole_number = 13) AS hole13_par,
       max(hole_yards) FILTER (WHERE hole_number = 13) AS hole13_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 13) AS hole13_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 13) AS hole13_fir,
       bool_or(gir) FILTER (WHERE hole_number = 13) AS hole13_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 13) AS hole13_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 13) AS hole13_putts,
       max(hole_score) FILTER (WHERE hole_number = 13) AS hole13_score,
       max(par) FILTER (WHERE hole_number = 14) AS hole14_par,
       max(hole_yards) FILTER (WHERE hole_number = 14) AS hole14_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 14) AS hole14_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 14) AS hole14_fir,
       bool_or(gir) FILTER (WHERE hole_number = 14) AS hole14_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 14) AS hole14_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 14) AS hole14_putts,
       max(hole_score) FILTER (WHERE hole_number = 14) AS hole14_score,
       max(par) FILTER (WHERE hole_number = 15) AS hole15_par,
       max(hole_yards) FILTER (WHERE hole_number = 15) AS hole15_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 15) AS hole15_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 15) AS hole15_fir,
       bool_or(gir) FILTER (WHERE hole_number = 15) AS hole15_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 15) AS hole15_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 15) AS hole15_putts,
       max(hole_score) FILTER (WHERE hole_number = 15) AS hole15_score,
       max(par) FILTER (WHERE hole_number = 16) AS hole16_par,
       max(hole_yards) FILTER (WHERE hole_number = 16) AS hole16_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 16) AS hole16_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 16) AS hole16_fir,
       bool_or(gir) FILTER (WHERE hole_number = 16) AS hole16_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 16) AS hole16_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 16) AS hole16_putts,
       max(hole_score) FILTER (WHERE hole_number = 16) AS hole16_score,
       max(par) FILTER (WHERE hole_number = 17) AS hole17_par,
       max(hole_yards) FILTER (WHERE hole_number = 17) AS hole17_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 17) AS hole17_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 17) AS hole17_fir,
       bool_or(gir) FILTER (WHERE hole_number = 17) AS hole17_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 17) AS hole17_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 17) AS hole17_putts,
       max(hole_score) FILTER (WHERE hole_number = 17) AS hole17_score,
       max(par) FILTER (WHERE hole_number = 18) AS hole18_par,
       max(hole_yards) FILTER (WHERE hole_number = 18) AS hole18_yards,
       max(drive_distance_yards) FILTER (WHERE hole_number = 18) AS hole18_drive_distance,
       bool_or(fir) FILTER (WHERE hole_number = 18) AS hole18_fir,
       bool_or(gir) FILTER (WHERE hole_number = 18) AS hole18_gir,
       max(gir_distance_to_hole_feet) FILTER (WHERE hole_number = 18) AS hole18_gir_distance_to_hole,
       max(putts) FILTER (WHERE hole_number = 18) AS hole18_putts,
       max(hole_score) FILTER (WHERE hole_number = 18) AS hole18_score,
       CASE WHEN count(*) FILTER (WHERE hole_number > 9) = 9
            THEN sum(hole_score) FILTER (WHERE hole_number > 9) END AS back9_score
FROM performance.player_tracker_hole
GROUP BY player_id, event_id, course_id, round_number;

CREATE OR REPLACE VIEW performance.player_tracker_round_totals AS
SELECT h.player_id, h.event_id, h.course_id, h.round_number, r.strokes AS score,
       r.score_to_par AS over_under, count(*) AS scored_holes, count(h.par) AS par_known_holes,
       CASE WHEN count(h.par) > 0 THEN count(*) FILTER (WHERE h.hole_score <= h.par - 2) END AS made_eagle_or_better,
       CASE WHEN count(h.par) > 0 THEN count(*) FILTER (WHERE h.hole_score = h.par - 1) END AS made_birdie,
       CASE WHEN count(h.par) > 0 THEN count(*) FILTER (WHERE h.hole_score = h.par) END AS made_par,
       CASE WHEN count(h.par) > 0 THEN count(*) FILTER (WHERE h.hole_score > h.par) END AS made_bogey_or_worse,
       avg(h.drive_distance_yards) AS drive_yards_average,
       count(h.drive_distance_yards) AS drives_measured,
       count(*) FILTER (WHERE h.fir) AS fir_yes_total, count(h.fir) AS fir_available_total,
       count(*) FILTER (WHERE h.gir) AS gir_yes_total, count(h.gir) AS gir_available_total,
       avg(h.gir_distance_to_hole_feet) FILTER (WHERE h.gir) AS gir_average_distance_feet,
       sum(h.putts) AS putts_total, count(h.putts) AS putts_known_holes,
       count(*) FILTER (WHERE h.putts = 1) AS one_putt_holes,
       count(*) FILTER (WHERE h.putts = 3) AS three_putt_holes
FROM performance.player_tracker_hole h
JOIN analytics.player_round r USING (player_id, event_id, course_id, round_number)
GROUP BY h.player_id, h.event_id, h.course_id, h.round_number, r.strokes, r.score_to_par;

-- A stable provider shot ID or reviewed disambiguation is required before
-- loading this table. Never derive identity from stroke number alone.
CREATE TABLE IF NOT EXISTS performance.player_tracker_shot_tourcast (
    shot_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_shot_id text NOT NULL CHECK (btrim(source_shot_id) <> ''),
    player_id uuid NOT NULL, event_id uuid NOT NULL, course_id uuid NOT NULL,
    round_number smallint NOT NULL, hole_number smallint NOT NULL CHECK (hole_number BETWEEN 1 AND 18),
    observation_id bigint NOT NULL REFERENCES intake.observation,
    par smallint CHECK (par BETWEEN 3 AND 6),
    coordinate_frame text,
    start_coordinates point, end_coordinates point,
    start_distance_to_pin_yards numeric CHECK (start_distance_to_pin_yards >= 0),
    start_shot_class text CHECK (start_shot_class IN ('drive','regular','chip','putt')),
    club text, shot_plane_degrees numeric, shot_direction_degrees numeric,
    shot_shape text CHECK (shot_shape IN ('hook','draw','straight','fade','slice')),
    shot_distance numeric CHECK (shot_distance >= 0),
    shot_distance_unit text CHECK (shot_distance_unit IN ('yd','ft')),
    shot_swing_speed_mph numeric CHECK (shot_swing_speed_mph >= 0),
    shot_apex_feet numeric CHECK (shot_apex_feet >= 0),
    shot_smash_rate numeric CHECK (shot_smash_rate >= 0),
    shot_outcome_location text CHECK (shot_outcome_location IN ('tee','fairway','green','rough','bunker','hazard','water','oob','hole')),
    shot_outcome_distance_to_pin_yards numeric CHECK (shot_outcome_distance_to_pin_yards >= 0),
    hole_finished boolean,
    UNIQUE (event_id, player_id, round_number, source_shot_id),
    CHECK ((shot_distance IS NULL) = (shot_distance_unit IS NULL)),
    CHECK (start_shot_class IS NULL OR shot_distance_unit IS NULL OR
           shot_distance_unit = CASE WHEN start_shot_class = 'putt' THEN 'ft' ELSE 'yd' END),
    CHECK ((start_coordinates IS NULL AND end_coordinates IS NULL) OR nullif(btrim(coordinate_frame), '') IS NOT NULL),
    FOREIGN KEY (event_id, player_id, round_number, course_id)
        REFERENCES analytics.player_round (event_id, player_id, round_number, course_id)
);

CREATE INDEX IF NOT EXISTS tracker_shot_round_hole ON performance.player_tracker_shot_tourcast
    (event_id, player_id, round_number, hole_number);

-- Model outputs are versioned and remain separate from the observed shot.
CREATE TABLE IF NOT EXISTS performance.shot_performance_predictability_output (
    shot_id uuid REFERENCES performance.player_tracker_shot_tourcast,
    model_version text CHECK (btrim(model_version) <> ''),
    as_of timestamptz,
    generated_at timestamptz NOT NULL DEFAULT now(),
    club text, shot_class text CHECK (shot_class IN ('drive','regular','chip','putt')),
    perfect_shot_zone jsonb,
    shot_start_distance_to_pin_yards numeric CHECK (shot_start_distance_to_pin_yards >= 0),
    shot_start_forecast_conditions_score numeric CHECK (shot_start_forecast_conditions_score BETWEEN 0 AND 10),
    shot_start_setting text CHECK (shot_start_setting IN ('fairway','rough','deep rough','hazard','green','tee','bunker')),
    shot_projection_difficulty_warning_score numeric CHECK (shot_projection_difficulty_warning_score BETWEEN 0 AND 10),
    outcome_percentile_low numeric CHECK (outcome_percentile_low BETWEEN 0 AND 100),
    outcome_percentile_high numeric CHECK (outcome_percentile_high BETWEEN 0 AND 100),
    shot_projection_output_performance_range jsonb,
    shot_type_performance_reliability numeric CHECK (shot_type_performance_reliability BETWEEN 0 AND 100),
    predicted_shot_outcome jsonb,
    player_skill_level_adjustment numeric,
    course_hole_conditions_difficulty_adjustment numeric,
    factors jsonb NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(factors) = 'object'),
    perfect_probability numeric CHECK (perfect_probability BETWEEN 0 AND 1),
    probable_probability numeric CHECK (probable_probability BETWEEN 0 AND 1),
    worst_probability numeric CHECK (worst_probability BETWEEN 0 AND 1),
    hole_potential_sg_percent numeric CHECK (hole_potential_sg_percent BETWEEN 0 AND 100),
    pre_shot_sg_percent numeric CHECK (pre_shot_sg_percent BETWEEN 0 AND 100),
    post_shot_sg_percent numeric CHECK (post_shot_sg_percent BETWEEN 0 AND 100),
    PRIMARY KEY (shot_id, model_version, as_of),
    CHECK (as_of <= generated_at),
    CHECK (outcome_percentile_low <= outcome_percentile_high),
    CHECK (num_nonnulls(perfect_probability, probable_probability, worst_probability) IN (0, 3)),
    CHECK (perfect_probability + probable_probability + worst_probability = 1),
    CHECK (shot_projection_difficulty_warning_score IS DISTINCT FROM 10 OR perfect_probability IS NULL OR perfect_probability = 0)
);

CREATE OR REPLACE VIEW performance.shot_predictability_display AS
SELECT s.player_id, s.event_id, s.course_id, s.round_number, s.hole_number,
       s.coordinate_frame, s.start_coordinates, s.end_coordinates, o.*,
       o.post_shot_sg_percent - o.pre_shot_sg_percent AS sg_change_percentage_points
FROM performance.player_tracker_shot_tourcast s
JOIN performance.shot_performance_predictability_output o USING (shot_id);

COMMIT;
