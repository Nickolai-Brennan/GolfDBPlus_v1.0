-- Apply after the public UUID foundation and the core reference migration.
BEGIN;
CREATE SCHEMA IF NOT EXISTS intake;
CREATE SCHEMA IF NOT EXISTS analytics;

-- A retry reuses its request key and observation timestamp. A fresh retrieval gets
-- a new timestamp even when its payload hash matches an earlier observation.
CREATE TABLE IF NOT EXISTS intake.observation (
    observation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    provider text NOT NULL CHECK (btrim(provider) <> ''),
    operation text NOT NULL CHECK (btrim(operation) <> ''),
    request_key text NOT NULL CHECK (btrim(request_key) <> ''),
    observed_at timestamptz NOT NULL,
    source_published_at timestamptz,
    payload_sha256 text NOT NULL CHECK (payload_sha256 ~ '^[0-9a-f]{64}$'),
    raw_uri text NOT NULL CHECK (btrim(raw_uri) <> ''),
    request_parameters jsonb NOT NULL DEFAULT '{}'
        CHECK (jsonb_typeof(request_parameters) = 'object'),
    UNIQUE (provider, operation, request_key, observed_at)
);

CREATE TABLE IF NOT EXISTS intake.record (
    observation_id bigint REFERENCES intake.observation,
    record_key text,
    payload jsonb NOT NULL,
    state text NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','accepted','quarantined')),
    reason text,
    CHECK (state <> 'quarantined' OR nullif(btrim(reason), '') IS NOT NULL),
    PRIMARY KEY (observation_id, record_key)
);
CREATE INDEX IF NOT EXISTS intake_pending ON intake.record (observation_id, record_key)
    WHERE state = 'pending';

-- IDs are text so provider formatting, including leading zeroes, survives.
CREATE TABLE IF NOT EXISTS intake.player_id_mapping (
    provider text NOT NULL CHECK (btrim(provider) <> ''),
    external_id text NOT NULL CHECK (btrim(external_id) <> ''),
    player_id uuid NOT NULL REFERENCES public.players_tracking(playerid),
    observation_id bigint REFERENCES intake.observation,
    PRIMARY KEY (provider, external_id)
);
CREATE TABLE IF NOT EXISTS intake.course_id_mapping (
    provider text NOT NULL CHECK (btrim(provider) <> ''),
    external_id text NOT NULL CHECK (btrim(external_id) <> ''),
    course_id uuid NOT NULL REFERENCES public.courses("coursesID"),
    observation_id bigint REFERENCES intake.observation,
    PRIMARY KEY (provider, external_id)
);

-- The season is part of the provider event identity. PGA TOUR leaderboard IDs
-- and tournament IDs can coexist under separate namespaces.
CREATE UNIQUE INDEX IF NOT EXISTS events_id_season ON public.events ("eventsID", "seasonID");
CREATE TABLE IF NOT EXISTS intake.event_id_mapping (
    provider text NOT NULL CHECK (btrim(provider) <> ''),
    namespace text NOT NULL DEFAULT 'tournament' CHECK (btrim(namespace) <> ''),
    season_id text,
    external_id text CHECK (btrim(external_id) <> ''),
    event_id uuid NOT NULL,
    observation_id bigint REFERENCES intake.observation,
    PRIMARY KEY (provider, namespace, season_id, external_id),
    FOREIGN KEY (event_id, season_id) REFERENCES public.events("eventsID", "seasonID")
);

-- Seed from the original provider columns. The mapping tables own future writes.
INSERT INTO intake.player_id_mapping (provider, external_id, player_id)
SELECT ids.provider, ids.external_id, p.playerid
FROM public.players_tracking p
CROSS JOIN LATERAL (VALUES ('pgatour',p."pgatourID"), ('datagolf',p."datagolfID"),
    ('espn',p."espnID"), ('cbssports',p."cbssportsID"), ('rickrungood',p."rickrungoodID"))
    AS ids(provider,external_id)
WHERE btrim(ids.external_id) <> ''
ON CONFLICT DO NOTHING;

INSERT INTO intake.course_id_mapping (provider, external_id, course_id)
SELECT ids.provider, ids.external_id, c."coursesID"
FROM public.courses c
CROSS JOIN LATERAL (VALUES ('pgatour',c."pgatour_coursesID"), ('datagolf',c."datagolf_coursesID"))
    AS ids(provider,external_id)
WHERE btrim(ids.external_id) <> ''
ON CONFLICT DO NOTHING;

INSERT INTO intake.event_id_mapping (provider, season_id, external_id, event_id)
SELECT ids.provider, e."seasonID", ids.external_id, e."eventsID"
FROM public.events e
CROSS JOIN LATERAL (VALUES ('pgatour',e."pgatour_eventsID"), ('datagolf',e."datagolf_eventsID"))
    AS ids(provider,external_id)
WHERE btrim(ids.external_id) <> ''
ON CONFLICT DO NOTHING;

CREATE INDEX IF NOT EXISTS player_mapping_entity ON intake.player_id_mapping (player_id);
CREATE INDEX IF NOT EXISTS course_mapping_entity ON intake.course_id_mapping (course_id);
CREATE INDEX IF NOT EXISTS event_mapping_entity ON intake.event_id_mapping (event_id);

CREATE TABLE IF NOT EXISTS analytics.player_info (
    player_id uuid PRIMARY KEY REFERENCES public.players_tracking(playerid),
    given_name text,
    family_name text,
    birth_date date,
    birthplace text,
    residence text,
    college text,
    is_amateur boolean,
    turned_pro_year smallint,
    headshot_url text,
    observation_id bigint REFERENCES intake.observation
);

CREATE TABLE IF NOT EXISTS analytics.course_info (
    course_id uuid PRIMARY KEY REFERENCES public.courses("coursesID"),
    latitude numeric CHECK (latitude BETWEEN -90 AND 90),
    longitude numeric CHECK (longitude BETWEEN -180 AND 180),
    altitude_ft numeric,
    observation_id bigint REFERENCES intake.observation
);

CREATE TABLE IF NOT EXISTS analytics.course_attributes (
    course_id uuid REFERENCES public.courses("coursesID"),
    setup_code text CHECK (btrim(setup_code) <> ''),
    valid_from date,
    observation_id bigint NOT NULL REFERENCES intake.observation,
    fairway_grass text,
    rough_grass text,
    green_grass text,
    fairway_width_yards numeric CHECK (fairway_width_yards > 0),
    green_area_sqft numeric CHECK (green_area_sqft > 0),
    green_speed_ft numeric CHECK (green_speed_ft > 0),
    PRIMARY KEY (course_id, setup_code, valid_from, observation_id)
);

CREATE TABLE IF NOT EXISTS analytics.event_info (
    event_id uuid PRIMARY KEY REFERENCES public.events("eventsID"),
    purse_amount numeric CHECK (purse_amount >= 0),
    purse_currency text CHECK (purse_currency ~ '^[A-Z]{3}$'),
    winner_fedex_points numeric CHECK (winner_fedex_points >= 0),
    observation_id bigint REFERENCES intake.observation,
    CHECK ((purse_amount IS NULL) = (purse_currency IS NULL))
);

CREATE TABLE IF NOT EXISTS analytics.event_course (
    event_id uuid REFERENCES public.events("eventsID"),
    course_id uuid REFERENCES public.courses("coursesID"),
    PRIMARY KEY (event_id, course_id)
);
INSERT INTO analytics.event_course
SELECT "eventsID","coursesID" FROM public.events WHERE "coursesID" IS NOT NULL
ON CONFLICT DO NOTHING;

-- Round 0 denotes an edition-level setup. An explicit round row overrides it.
CREATE TABLE IF NOT EXISTS analytics.course_scorecard (
    event_id uuid,
    course_id uuid,
    round_number smallint CHECK (round_number BETWEEN 0 AND 4),
    hole_number smallint CHECK (hole_number BETWEEN 1 AND 18),
    par smallint NOT NULL CHECK (par BETWEEN 3 AND 6),
    yards integer CHECK (yards > 0),
    observation_id bigint REFERENCES intake.observation,
    PRIMARY KEY (event_id, course_id, round_number, hole_number),
    FOREIGN KEY (event_id, course_id) REFERENCES analytics.event_course
);

-- An immutable publication key allows repeated leaderboard snapshots and ties.
CREATE TABLE IF NOT EXISTS analytics.event_leaderboard (
    event_id uuid REFERENCES public.events("eventsID"),
    observation_id bigint REFERENCES intake.observation,
    player_id uuid REFERENCES public.players_tracking(playerid),
    position integer CHECK (position > 0),
    position_display text,
    score_to_par integer,
    thru_display text,
    status text,
    PRIMARY KEY (event_id, observation_id, player_id)
);

CREATE TABLE IF NOT EXISTS analytics.event_results (
    event_id uuid REFERENCES public.events("eventsID"),
    player_id uuid REFERENCES public.players_tracking(playerid),
    observation_id bigint NOT NULL REFERENCES intake.observation,
    position integer CHECK (position > 0),
    position_display text,
    status text NOT NULL,
    total_strokes integer CHECK (total_strokes > 0),
    score_to_par integer,
    earnings_amount numeric CHECK (earnings_amount >= 0),
    earnings_currency text CHECK (earnings_currency ~ '^[A-Z]{3}$'),
    fedex_points numeric CHECK (fedex_points >= 0),
    CHECK ((earnings_amount IS NULL) = (earnings_currency IS NULL)),
    PRIMARY KEY (event_id, player_id, observation_id)
);
CREATE INDEX IF NOT EXISTS event_results_player ON analytics.event_results (player_id, event_id);

CREATE TABLE IF NOT EXISTS analytics.player_round (
    event_id uuid REFERENCES public.events("eventsID"),
    player_id uuid REFERENCES public.players_tracking(playerid),
    round_number smallint CHECK (round_number BETWEEN 1 AND 4),
    course_id uuid,
    observation_id bigint NOT NULL REFERENCES intake.observation,
    tee_time timestamptz,
    start_hole smallint CHECK (start_hole BETWEEN 1 AND 18),
    strokes integer CHECK (strokes > 0),
    score_to_par integer,
    PRIMARY KEY (event_id, player_id, round_number),
    UNIQUE (event_id, player_id, round_number, course_id),
    FOREIGN KEY (event_id, course_id) REFERENCES analytics.event_course
);

CREATE TABLE IF NOT EXISTS analytics.player_hole_score (
    event_id uuid,
    player_id uuid,
    round_number smallint,
    hole_number smallint CHECK (hole_number BETWEEN 1 AND 18),
    course_id uuid NOT NULL,
    observation_id bigint NOT NULL REFERENCES intake.observation,
    strokes smallint NOT NULL CHECK (strokes > 0),
    PRIMARY KEY (event_id, player_id, round_number, hole_number),
    FOREIGN KEY (event_id, player_id, round_number, course_id)
        REFERENCES analytics.player_round (event_id, player_id, round_number, course_id)
);
CREATE INDEX IF NOT EXISTS hole_scores_course ON analytics.player_hole_score
    (course_id, event_id, round_number, hole_number);

-- Published aggregates are source evidence. They do not feed the derived
-- views unless an explicit reconciliation rule is added.
CREATE TABLE IF NOT EXISTS analytics.course_hole_source_metrics (
    event_id uuid,
    course_id uuid,
    round_number smallint CHECK (round_number BETWEEN 0 AND 4),
    hole_number smallint CHECK (hole_number BETWEEN 1 AND 18),
    observation_id bigint REFERENCES intake.observation,
    sample_count integer CHECK (sample_count >= 0),
    avg_strokes numeric CHECK (avg_strokes > 0),
    avg_to_par numeric,
    source_rank integer CHECK (source_rank > 0),
    PRIMARY KEY (event_id, course_id, round_number, hole_number, observation_id),
    FOREIGN KEY (event_id, course_id) REFERENCES analytics.event_course
);

CREATE TABLE IF NOT EXISTS analytics.metric_definition (
    metric_code text,
    version integer CHECK (version > 0),
    label text NOT NULL,
    definition text NOT NULL,
    unit_code text REFERENCES core.measurement_units(code),
    PRIMARY KEY (metric_code, version)
);

CREATE TABLE IF NOT EXISTS intake.metric_id_mapping (
    provider text NOT NULL CHECK (btrim(provider) <> ''),
    external_id text NOT NULL CHECK (btrim(external_id) <> ''),
    metric_code text NOT NULL,
    metric_version integer NOT NULL,
    PRIMARY KEY (provider, external_id),
    FOREIGN KEY (metric_code, metric_version) REFERENCES analytics.metric_definition
);

-- NULL event/round means season grain. NULL round alone means event grain.
-- Published provider statistics and calculated values retain distinct observations.
CREATE TABLE IF NOT EXISTS analytics.player_statistics (
    statistic_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_id uuid NOT NULL REFERENCES public.players_tracking(playerid),
    season_id text NOT NULL REFERENCES public.seasons("seasonID"),
    event_id uuid,
    round_number smallint CHECK (round_number BETWEEN 1 AND 4),
    metric_code text NOT NULL,
    metric_version integer NOT NULL,
    observation_id bigint NOT NULL REFERENCES intake.observation,
    numeric_value numeric,
    display_value text,
    sample_count integer CHECK (sample_count >= 0),
    numerator numeric,
    denominator numeric CHECK (denominator >= 0),
    CHECK (numeric_value IS NOT NULL OR display_value IS NOT NULL),
    CHECK (round_number IS NULL OR event_id IS NOT NULL),
    FOREIGN KEY (event_id, season_id) REFERENCES public.events("eventsID", "seasonID"),
    FOREIGN KEY (event_id, player_id, round_number) REFERENCES analytics.player_round,
    FOREIGN KEY (metric_code, metric_version) REFERENCES analytics.metric_definition,
    UNIQUE NULLS NOT DISTINCT
        (player_id, season_id, event_id, round_number, metric_code, metric_version, observation_id)
);

-- A model run owns its own evidence cutoff. A new run preserves previous outputs.
CREATE TABLE IF NOT EXISTS analytics.player_output (
    output_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_id uuid NOT NULL REFERENCES public.players_tracking(playerid),
    model_code text NOT NULL,
    model_version text NOT NULL,
    run_id uuid NOT NULL,
    event_id uuid REFERENCES public.events("eventsID"),
    as_of timestamptz NOT NULL,
    generated_at timestamptz NOT NULL DEFAULT now(),
    output_code text NOT NULL,
    numeric_value numeric,
    display_value text,
    sample_count integer CHECK (sample_count >= 0),
    observation_id bigint NOT NULL REFERENCES intake.observation,
    CHECK (numeric_value IS NOT NULL OR display_value IS NOT NULL),
    CHECK (as_of <= generated_at),
    UNIQUE NULLS NOT DISTINCT (run_id, model_code, model_version, player_id, event_id, output_code)
);

CREATE INDEX IF NOT EXISTS player_statistics_lookup
    ON analytics.player_statistics (player_id, season_id, observation_id);
CREATE INDEX IF NOT EXISTS player_output_lookup
    ON analytics.player_output (player_id, model_code, generated_at DESC);

CREATE OR REPLACE VIEW analytics.schedule_tour_season AS
SELECT e."eventsID" AS event_id, s."seasonID" AS season_id, t."tourID" AS tour_id,
       s.season_year, t.tour_name, e.event_name, e.starts_on, e.ends_on,
       e."coursesID" AS primary_course_id, e.event_status_code, e.event_type_code,
       i.purse_amount, i.purse_currency, i.winner_fedex_points
FROM public.events e
JOIN public.seasons s ON s."seasonID" = e."seasonID"
JOIN public.tours t ON t."tourID" = s."tourID"
LEFT JOIN analytics.event_info i ON i.event_id = e."eventsID";

-- Count each player-hole once. Unknown par is visible through par_sample_count.
-- Full-event averages are weighted by player-hole observations.
CREATE OR REPLACE VIEW analytics.course_hole_metrics AS
WITH scoring AS (
    SELECT h.*, coalesce(r.par, e.par) AS par
    FROM analytics.player_hole_score h
    LEFT JOIN analytics.course_scorecard r
      ON (r.event_id,r.course_id,r.round_number,r.hole_number) =
         (h.event_id,h.course_id,h.round_number,h.hole_number)
    LEFT JOIN analytics.course_scorecard e
      ON (e.event_id,e.course_id,e.round_number,e.hole_number) =
         (h.event_id,h.course_id,0,h.hole_number)
)
SELECT event_id, course_id, hole_number, coalesce(round_number,0::smallint) AS round_number,
       count(*) AS sample_count, count(par) AS par_sample_count,
       sum(strokes) AS total_strokes, sum(strokes - par) AS total_to_par,
       avg(strokes) AS avg_strokes, avg(strokes - par) AS avg_to_par,
       count(*) FILTER (WHERE strokes - par <= -2) AS eagle_or_better,
       count(*) FILTER (WHERE strokes - par = -1) AS birdie,
       count(*) FILTER (WHERE strokes - par = 0) AS par_count,
       count(*) FILTER (WHERE strokes - par = 1) AS bogey,
       count(*) FILTER (WHERE strokes - par = 2) AS double_bogey,
       count(*) FILTER (WHERE strokes - par >= 3) AS triple_bogey_or_worse
FROM scoring
GROUP BY GROUPING SETS ((event_id,course_id,hole_number,round_number),
                       (event_id,course_id,hole_number));

CREATE OR REPLACE VIEW analytics.course_performance AS
SELECT event_id, course_id, sum(sample_count) AS sample_count,
       sum(par_sample_count) AS par_sample_count, sum(total_strokes) AS total_strokes,
       sum(total_to_par) AS total_to_par,
       sum(total_strokes) / nullif(sum(sample_count),0) AS avg_strokes_per_hole,
       sum(total_to_par) / nullif(sum(par_sample_count),0) AS avg_to_par_per_hole
FROM analytics.course_hole_metrics
WHERE round_number = 0
GROUP BY event_id, course_id;

CREATE OR REPLACE VIEW analytics.course_difficulty_evaluation AS
WITH splits AS (
    SELECT CASE WHEN grouping(p.event_id) = 1 THEN 'season' ELSE 'event' END AS split,
           e."seasonID" AS season_id, p.event_id, p.course_id,
           sum(p.sample_count) AS sample_count, sum(p.par_sample_count) AS par_sample_count,
           sum(p.total_to_par) / nullif(sum(p.par_sample_count),0) AS avg_to_par_per_hole
    FROM analytics.course_performance p
    JOIN public.events e ON e."eventsID" = p.event_id
    GROUP BY GROUPING SETS ((e."seasonID",p.event_id,p.course_id),
                           (e."seasonID",p.course_id))
)
SELECT splits.*,
       CASE WHEN par_sample_count > 0 THEN dense_rank() OVER (
           PARTITION BY split,season_id,event_id ORDER BY avg_to_par_per_hole DESC NULLS LAST
       ) END AS difficulty_rank
FROM splits;

COMMIT;
