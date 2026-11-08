-- PostgreSQL 15+. Apply once to a new database via psql -v ON_ERROR_STOP=1.
BEGIN;
CREATE SCHEMA ingest;
CREATE SCHEMA golf;
CREATE SCHEMA reporting;

-- Immutable raw files/responses live at storage_uri. The digest makes retries idempotent.
CREATE TABLE ingest.source (
    source_code text PRIMARY KEY,
    display_name text NOT NULL
);
INSERT INTO ingest.source VALUES
    ('historical_tsv', 'Historical PGA results TSV'),
    ('pga_tour', 'PGA TOUR / Tourcast'),
    ('owgr', 'Official World Golf Ranking'),
    ('golfdb_plus', 'GolfDB+'),
    ('datagolf', 'Data Golf'),
    ('shot_tracker', 'Shot Tracker');

CREATE TABLE ingest.batch (
    batch_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_code text NOT NULL REFERENCES ingest.source,
    dataset text NOT NULL,
    sha256 text NOT NULL CHECK (sha256 ~ '^[a-f0-9]{64}$'),
    storage_uri text NOT NULL,
    retrieved_at timestamptz NOT NULL DEFAULT now(),
    request_context jsonb NOT NULL DEFAULT '{}',
    parser_version text,
    status text NOT NULL DEFAULT 'received'
        CHECK (status IN ('received', 'validated', 'loaded', 'failed')),
    UNIQUE (source_code, dataset, sha256)
);

CREATE TABLE ingest.record (
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    record_key text NOT NULL,
    payload jsonb NOT NULL,
    resolution_status text NOT NULL DEFAULT 'pending'
        CHECK (resolution_status IN ('pending', 'loaded', 'duplicate', 'rejected', 'needs_review')),
    issue text,
    PRIMARY KEY (batch_id, record_key)
);

CREATE TABLE golf.player (
    player_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    display_name text NOT NULL,
    given_name text,
    family_name text,
    birth_date date,
    nationality_code text,
    headshot_url text,
    is_amateur boolean
);

CREATE TABLE golf.tour (
    tour_id text PRIMARY KEY,
    tour_name text NOT NULL
);
INSERT INTO golf.tour VALUES ('pga', 'PGA TOUR');

-- Tour season labels can differ from the calendar year of play.
CREATE TABLE golf.tour_season (
    tour_id text REFERENCES golf.tour,
    season smallint, -- year
    season_label text,
    starts_on date,
    ends_on date,
    CHECK (starts_on <= ends_on),
    PRIMARY KEY (tour_id, season)
);

CREATE TABLE golf.course (
    course_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_name text NOT NULL,
    city text,
    region text,
    country_code text,
    timezone_name text,
    fairway_grass text,
    green_grass text
);
CREATE TABLE golf.course_hole (
    course_id bigint REFERENCES golf.course,
    hole_number smallint CHECK (hole_number > 0),
    nominal_par smallint CHECK (nominal_par > 0),
    nominal_yards integer CHECK (nominal_yards > 0),
    PRIMARY KEY (course_id, hole_number)
);

CREATE TABLE golf.event_series (
    event_series_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    canonical_name text NOT NULL
);
CREATE TABLE golf.event_edition (
    event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_series_id bigint NOT NULL REFERENCES golf.event_series,
    event_name text NOT NULL,
    start_date date,
    end_date date,
    location text,
    city text,
    region text,
    country_code text,
    timezone_name text,
    format_code text,
    event_status text,
    schedule_batch_id bigint REFERENCES ingest.batch,
    CHECK (start_date <= end_date)
);
-- One physical edition may appear on multiple tour calendars.
CREATE TABLE golf.schedule_entry (
    tour_id text,
    season smallint,
    event_id bigint REFERENCES golf.event_edition,
    purse_amount numeric(16,2) CHECK (purse_amount >= 0),
    purse_currency text CHECK (purse_currency ~ '^[A-Z]{3}$'),
    winner_fedex_points numeric(14,4) CHECK (winner_fedex_points >= 0),
    terms_batch_id bigint REFERENCES ingest.batch,
    CHECK ((purse_amount IS NULL) = (purse_currency IS NULL)),
    PRIMARY KEY (tour_id, season, event_id),
    FOREIGN KEY (tour_id, season) REFERENCES golf.tour_season
);

-- The namespace distinguishes IDs with different meanings within the same provider.
CREATE TABLE golf.player_external_id (
    source_code text REFERENCES ingest.source,
    id_namespace text,
    external_id text,
    player_id bigint NOT NULL REFERENCES golf.player,
    PRIMARY KEY (source_code, id_namespace, external_id)
);
CREATE TABLE golf.course_external_id (
    source_code text REFERENCES ingest.source,
    id_namespace text,
    external_id text,
    course_id bigint NOT NULL REFERENCES golf.course,
    PRIMARY KEY (source_code, id_namespace, external_id)
);
CREATE TABLE golf.event_external_id (
    source_code text REFERENCES ingest.source,
    id_namespace text,
    external_id text,
    event_id bigint NOT NULL REFERENCES golf.event_edition,
    PRIMARY KEY (source_code, id_namespace, external_id)
);

CREATE TABLE golf.event_course (
    event_id bigint REFERENCES golf.event_edition,
    course_id bigint REFERENCES golf.course,
    is_host boolean,
    PRIMARY KEY (event_id, course_id)
);
CREATE TABLE golf.event_round (
    event_id bigint REFERENCES golf.event_edition,
    course_id bigint REFERENCES golf.course,
    round_number smallint CHECK (round_number > 0),
    played_on date,
    round_status text,
    PRIMARY KEY (event_id, round_number, course_id)
);
-- A row records the configuration actually used in that round.
CREATE TABLE golf.round_hole_setup (
    event_id bigint,
    round_number smallint,
    course_id bigint,
    hole_number smallint,
    par smallint CHECK (par > 0),
    yards integer CHECK (yards > 0),
    PRIMARY KEY (event_id, round_number, course_id, hole_number),
    FOREIGN KEY (event_id, round_number, course_id) REFERENCES golf.event_round,
    FOREIGN KEY (event_id, course_id) REFERENCES golf.event_course,
    FOREIGN KEY (course_id, hole_number) REFERENCES golf.course_hole
);

CREATE TABLE golf.event_result (
    event_id bigint REFERENCES golf.event_edition,
    player_id bigint REFERENCES golf.player,
    finish_label text,
    finish_rank integer CHECK (finish_rank > 0),
    result_status text,
    strokes_total integer CHECK (strokes_total > 0),
    score_to_par integer,
    earnings_amount numeric(16,2) CHECK (earnings_amount >= 0),
    earnings_currency text CHECK (earnings_currency ~ '^[A-Z]{3}$'),
    fedex_points numeric(14,4) CHECK (fedex_points >= 0),
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    CHECK ((earnings_amount IS NULL) = (earnings_currency IS NULL)),
    PRIMARY KEY (event_id, player_id)
);
CREATE TABLE golf.player_round (
    event_id bigint,
    player_id bigint,
    round_number smallint,
    course_id bigint,
    start_hole smallint CHECK (start_hole > 0),
    tee_time_local time,
    tee_at timestamptz,
    strokes integer CHECK (strokes > 0),
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    PRIMARY KEY (event_id, player_id, round_number),
    UNIQUE (event_id, player_id, round_number, course_id),
    FOREIGN KEY (event_id, player_id) REFERENCES golf.event_result,
    FOREIGN KEY (event_id, round_number, course_id) REFERENCES golf.event_round,
    FOREIGN KEY (event_id, course_id) REFERENCES golf.event_course
);
CREATE TABLE golf.player_hole (
    event_id bigint,
    player_id bigint,
    round_number smallint,
    course_id bigint NOT NULL,
    hole_number smallint,
    hole_sequence smallint CHECK (hole_sequence > 0),
    strokes smallint CHECK (strokes > 0),
    putts smallint CHECK (putts >= 0),
    fairway_hit boolean,
    green_in_regulation boolean,
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    CHECK (putts <= strokes),
    PRIMARY KEY (event_id, player_id, round_number, hole_number),
    FOREIGN KEY (event_id, player_id, round_number, course_id)
        REFERENCES golf.player_round (event_id, player_id, round_number, course_id),
    FOREIGN KEY (event_id, round_number, course_id, hole_number) REFERENCES golf.round_hole_setup
);

CREATE TABLE golf.shot (
    shot_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id bigint NOT NULL,
    course_id bigint NOT NULL,
    player_id bigint NOT NULL,
    round_number smallint NOT NULL,
    hole_number smallint NOT NULL,
    shot_number smallint NOT NULL CHECK (shot_number > 0),
    shot_type text,
    club text,
    hit_at timestamptz,
    from_lie text,
    to_lie text,
    distance_yards numeric CHECK (distance_yards >= 0),
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    UNIQUE (event_id, player_id, round_number, hole_number, shot_number),
    FOREIGN KEY (event_id, player_id, round_number, hole_number) REFERENCES golf.player_hole,
    FOREIGN KEY (event_id, round_number, course_id, hole_number) REFERENCES golf.round_hole_setup

);


CREATE TABLE golf.shot_radar (
    shot_id bigint PRIMARY KEY REFERENCES golf.shot,
    ball_speed_mph numeric CHECK (ball_speed_mph > 0),
    clubhead_speed_mph numeric CHECK (clubhead_speed_mph > 0),
    spin_rpm numeric CHECK (spin_rpm >= 0),
    apex_ft numeric CHECK (apex_ft >= 0),
    smash_factor numeric CHECK (smash_factor > 0),
    batch_id bigint NOT NULL REFERENCES ingest.batch
);

CREATE TABLE golf.coordinate_frame (
    frame_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    frame_key text NOT NULL UNIQUE,
    units text NOT NULL,
    axis_definition text NOT NULL,
    reference_system text,
    origin_metadata jsonb
);
-- Points can represent measured, provider-rendered or modeled paths.
CREATE TABLE golf.shot_path (
    path_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shot_id bigint NOT NULL REFERENCES golf.shot,
    frame_id bigint NOT NULL REFERENCES golf.coordinate_frame,
    path_kind text NOT NULL
        CHECK (path_kind IN ('endpoints', 'observed', 'provider_rendered', 'modeled')),
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    UNIQUE (shot_id, frame_id, path_kind, batch_id)
);
CREATE TABLE golf.shot_path_point (
    path_id bigint REFERENCES golf.shot_path,
    point_index integer CHECK (point_index >= 0),
    x double precision NOT NULL,
    y double precision NOT NULL,
    z double precision,
    elapsed_ms integer CHECK (elapsed_ms >= 0),
    PRIMARY KEY (path_id, point_index)
);
CREATE TABLE golf.shot_media (
    shot_id bigint REFERENCES golf.shot,
    source_code text REFERENCES ingest.source,
    external_media_id text,
    share_url text,
    playback_url text,
    thumbnail_url text,
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    PRIMARY KEY (shot_id, source_code, external_media_id)
);

-- Keep units, scale and calculation version beside the definition.
CREATE TABLE golf.metric_definition (
    metric_code text,
    definition_version integer CHECK (definition_version > 0),
    metric_name text NOT NULL,
    category text NOT NULL,
    description text NOT NULL,
    unit_code text NOT NULL,
    scale_min numeric,
    scale_max numeric,
    CHECK (scale_min <= scale_max),
    PRIMARY KEY (metric_code, definition_version)
);
-- Context is defined by the combination of season, edition, player, course and round.
-- Supported here: tour season, player season, event, player event/round, course and course hole.
CREATE TABLE golf.metric_observation (
    observation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    metric_code text NOT NULL,
    definition_version integer NOT NULL,
    source_code text NOT NULL REFERENCES ingest.source,
    tour_id text NOT NULL,
    season smallint NOT NULL,
    event_id bigint,
    player_id bigint REFERENCES golf.player,
    round_number smallint,
    course_id bigint REFERENCES golf.course,
    hole_number smallint,
    as_of_date date NOT NULL,
    value_numeric numeric,
    value_text text,
    numerator numeric,
    denominator numeric CHECK (denominator >= 0),
    sample_size integer CHECK (sample_size >= 0),
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    CHECK (value_numeric IS NOT NULL OR value_text IS NOT NULL),
    CHECK (round_number IS NULL OR event_id IS NOT NULL),
    CHECK (player_id IS NULL OR course_id IS NULL),
    CHECK (hole_number IS NULL OR course_id IS NOT NULL),
    FOREIGN KEY (metric_code, definition_version) REFERENCES golf.metric_definition,
    FOREIGN KEY (tour_id, season) REFERENCES golf.tour_season,
    FOREIGN KEY (tour_id, season, event_id) REFERENCES golf.schedule_entry,
    FOREIGN KEY (event_id, player_id) REFERENCES golf.event_result,
    FOREIGN KEY (event_id, round_number, course_id) REFERENCES golf.event_round,
    FOREIGN KEY (event_id, player_id, round_number) REFERENCES golf.player_round,
    FOREIGN KEY (event_id, course_id) REFERENCES golf.event_course,
    FOREIGN KEY (course_id, hole_number) REFERENCES golf.course_hole,
    FOREIGN KEY (event_id, round_number, course_id, hole_number) REFERENCES golf.round_hole_setup,
    UNIQUE NULLS NOT DISTINCT (metric_code, definition_version, source_code,
        tour_id, season, event_id, player_id, round_number, course_id, hole_number, as_of_date)
);

CREATE TABLE golf.ranking_system (
    ranking_code text PRIMARY KEY,
    display_name text NOT NULL,
    source_code text NOT NULL REFERENCES ingest.source
);
INSERT INTO golf.ranking_system VALUES
    ('owgr', 'OWGR', 'owgr'),
    ('golfdb_plus', 'GolfDB+', 'golfdb_plus'),
    ('datagolf', 'Data Golf', 'datagolf');

CREATE TABLE golf.ranking_snapshot (
    snapshot_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ranking_code text NOT NULL REFERENCES golf.ranking_system,
    ranking_date date NOT NULL,
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    is_complete boolean NOT NULL DEFAULT false,
    UNIQUE (ranking_code, ranking_date)
);
CREATE TABLE golf.ranking_entry (
    snapshot_id bigint REFERENCES golf.ranking_snapshot,
    player_id bigint REFERENCES golf.player,
    rank integer NOT NULL CHECK (rank > 0),
    rating numeric,
    PRIMARY KEY (snapshot_id, player_id)
);

CREATE TABLE golf.fedex_snapshot (
    snapshot_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tour_id text NOT NULL,
    season smallint NOT NULL,
    standings_phase text NOT NULL,
    as_of_at timestamptz NOT NULL,
    is_official boolean NOT NULL,
    is_complete boolean NOT NULL DEFAULT false,
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    FOREIGN KEY (tour_id, season) REFERENCES golf.tour_season,
    UNIQUE (tour_id, season, standings_phase, is_official, as_of_at)
);
CREATE TABLE golf.fedex_entry (
    snapshot_id bigint REFERENCES golf.fedex_snapshot,
    player_id bigint REFERENCES golf.player,
    rank integer NOT NULL CHECK (rank > 0),
    total_pts numeric(14,4) NOT NULL CHECK (total_pts >= 0),
    events_played integer CHECK (events_played >= 0),
    season_winnings numeric(16,2) CHECK (season_winnings >= 0),
    winnings_currency text CHECK (winnings_currency ~ '^[A-Z]{3}$'),
    CHECK ((season_winnings IS NULL) = (winnings_currency IS NULL)),
    PRIMARY KEY (snapshot_id, player_id)
);

CREATE INDEX event_result_player_idx ON golf.event_result (player_id, event_id);
CREATE INDEX shot_player_idx ON golf.shot (player_id, event_id, round_number);
CREATE INDEX event_edition_date_idx ON golf.event_edition (start_date);
CREATE INDEX metric_player_idx ON golf.metric_observation (player_id, metric_code, as_of_date);
CREATE INDEX metric_course_idx ON golf.metric_observation (course_id, metric_code, as_of_date);

-- Use one complete publication per source per calendar quarter. Selecting the
-- snapshot before the player rows prevents an earlier rank from being carried forward.
CREATE VIEW reporting.player_rankings_quarterly AS
WITH dated AS (
    SELECT snapshot_id, ranking_code, ranking_date,
           date_trunc('quarter', ranking_date::timestamp)::date AS quarter_start
    FROM golf.ranking_snapshot
    WHERE is_complete
), selected AS (
    SELECT DISTINCT ON (ranking_code, quarter_start) *
    FROM dated
    ORDER BY ranking_code, quarter_start, ranking_date DESC
)
SELECT s.quarter_start,
       (s.quarter_start + interval '3 months')::date - 1 AS quarter_end,
       p.player_id, p.display_name AS player,
       max(e.rank) FILTER (WHERE s.ranking_code = 'owgr') AS owgr_rank,
       max(e.rank) FILTER (WHERE s.ranking_code = 'golfdb_plus') AS golfdb_plus_rank,
       max(e.rank) FILTER (WHERE s.ranking_code = 'datagolf') AS datagolf_rank,
       max(s.ranking_date) FILTER (WHERE s.ranking_code = 'owgr') AS owgr_as_of,
       max(s.ranking_date) FILTER (WHERE s.ranking_code = 'golfdb_plus') AS golfdb_plus_as_of,
       max(s.ranking_date) FILTER (WHERE s.ranking_code = 'datagolf') AS datagolf_as_of
FROM selected s
JOIN golf.ranking_entry e USING (snapshot_id)
JOIN golf.player p USING (player_id)
GROUP BY s.quarter_start, p.player_id, p.display_name;

-- Published standings are selected at snapshot level, independently by phase.
CREATE VIEW reporting.fedex_cup_standings AS
WITH selected AS (
    SELECT DISTINCT ON (tour_id, season, standings_phase)
           snapshot_id, tour_id, season, standings_phase, as_of_at
    FROM golf.fedex_snapshot
    WHERE is_official AND is_complete
    ORDER BY tour_id, season, standings_phase, as_of_at DESC
)
SELECT s.season, s.tour_id, s.standings_phase, s.as_of_at,
       e.rank, p.player_id, p.display_name AS player, e.total_pts,
       e.events_played, e.season_winnings, e.winnings_currency
FROM selected s
JOIN golf.fedex_entry e USING (snapshot_id)
JOIN golf.player p USING (player_id);

CREATE VIEW reporting.pga_schedule AS
SELECT s.season, s.tour_id, e.event_id, e.event_name,
       e.start_date, e.end_date, e.location, e.city, e.region,
       e.country_code AS country, s.purse_amount AS event_winnings,
       s.purse_currency AS currency, s.winner_fedex_points AS event_fedex_points,
       e.event_status
FROM golf.schedule_entry s
JOIN golf.event_edition e USING (event_id)
WHERE s.tour_id = 'pga';

COMMIT;
